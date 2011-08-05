#!/usr/bin/perl -w
# --
# dealing with spam
# based on PendingJobs.pl - check pending tickets
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# Copyright (C) 2008 Osvaldo T. Suarez http://www.otsuarez.com/
# --
# --

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin)."/Kernel/cpan-lib";

use strict;

use vars qw($VERSION);
$VERSION = '$Revision: 1.27 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

use Date::Pcalc qw(Day_of_Week Day_of_Week_Abbreviation);
use Date::Parse qw(str2time);
use Kernel::Config;
use Kernel::System::Time;
use Kernel::System::Log;
use Kernel::System::Main;
use Kernel::System::DB;
use Kernel::System::Ticket;
use Kernel::System::User;
use Kernel::System::State;

# common objects
my %CommonObject = ();
$CommonObject{ConfigObject} = Kernel::Config->new();
$CommonObject{LogObject} = Kernel::System::Log->new(
    LogPrefix => 'OTRS-PendingJobs',
    %CommonObject,
);
$CommonObject{MainObject} = Kernel::System::Main->new(%CommonObject);
$CommonObject{TimeObject} = Kernel::System::Time->new(%CommonObject);
$CommonObject{DBObject} = Kernel::System::DB->new(%CommonObject);
$CommonObject{TicketObject} = Kernel::System::Ticket->new(%CommonObject);
$CommonObject{UserObject} = Kernel::System::User->new(%CommonObject);
$CommonObject{StateObject} = Kernel::System::State->new(%CommonObject);

# --------------------------------------------- #

my @TicketIDs = ();

# tickets with state of "new" and on "Junk" queue
# queue_id = 2 -> Raw Queue
# queue_id = 3 -> Junk Queue

    my $SQL = "SELECT st.id FROM  ticket st  WHERE st.queue_id = '3' AND  st.ticket_state_id = '1'";
    $CommonObject{DBObject}->Prepare(SQL => $SQL);
    while (my @RowTmp = $CommonObject{DBObject}->FetchrowArray()) {
    push (@TicketIDs, $RowTmp[0]);
    }
my $TicketID;

# checking the tickets we care about
foreach (@TicketIDs) {
  my  $TicketID = "$_";
  my %Ticket = $CommonObject{TicketObject}->TicketGet(TicketID => $_);

  if (!%Ticket) {
  exit 1;
  }

  my %Article = $CommonObject{TicketObject}->ArticleFirstArticle( TicketID => $TicketID,);
  my $myAID = $Article{ArticleID};
  my $PlainMessage = $CommonObject{TicketObject}->ArticlePlain(ArticleID => $myAID);
  # first place a copy of the email on a directory where the antispam system (sa-learn) could pick it up
  open(FF,">/var/otrs/spam/$myAID");
  print FF "$PlainMessage";
  close(FF);
  # change the userid to ease searches later on
  $CommonObject{TicketObject}->OwnerSet(
          TicketID => $TicketID,
        NewUserID => 8, # id = 8, login = spamuser
        SendNoNotification => 0, # optional 1|0 (send no agent and customer notification)
        UserID => 1,
    );
    # now let's close the ticket and we're good to go
  $CommonObject{TicketObject}->StateSet(
          State => 'removed',
          TicketID => $TicketID,
          SendNoNotification => 0, # optional 1|0 (send no agent and customer notification)
          UserID => 8, # id = 8, login = spamuser
  );

}

exit (0);

