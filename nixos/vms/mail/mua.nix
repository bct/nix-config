{
  config,
  pkgs,
  ...
}:
{
  imports = [ ./neomutt.nix ];

  users.users.bct = {
    # put home directory in /var so that we can have a single writeable volume.
    home = "/var/home/bct";

    # give me access to the mailboxes
    extraGroups = [ config.mailserver.vmailGroupName ];
  };

  environment.systemPackages = [
    pkgs.neomutt
    pkgs.notmuch
    pkgs.afew
    pkgs.msmtp
    pkgs.procmail
    pkgs.w3m
  ];

  systemd.timers.notmuch-new = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "5m";
      Unit = "notmuch-new.service";
    };
  };

  systemd.services.notmuch-new = {
    serviceConfig = {
      Type = "oneshot";
      User = "bct";
      Group = "virtualMail";
      ExecStart = "${pkgs.notmuch}/bin/notmuch new --quiet";
    };
  };

  home-manager.users.bct = {
    home.file.".mailcap".text = ''
      text/html; w3m -I %{charset} -T text/html -o display_link_number=1; nametemplate=%s.html; copiousoutput
    '';

    home.file.".procmailrc".text = ''
      MAILDIR=/var/vmail/diffeq.com/bct/mail/
      #LOGABSTRACT=all
      #LOGFILE=$HOME/maillog
      #VERBOSE=on
      UMASK=007

      ### spam can go to hell
      :0:
      * ^X-Spam: yes
      Junk/

      ### catch-all address gets its own folder
      :0:
      * ! ^Delivered-To: bct@diffeq.com
      * ! ^From: .*bct@diffeq.com
      catchall/

      ### github
      :0:
      * ^From: .*@github.com
      github/

      ### mailing list catch-all
      :0:
      * ^(Mailing-List|List-Id):.*
      lists/

      ### All unmatched mail goes to inbox
      :0:
      ./
    '';

    home.file.".notmuch-config".text = ''
      # .notmuch-config - Configuration file for the notmuch mail system
      #
      # For more information about notmuch, see https://notmuchmail.org
      # Database configuration
      #
      # The only value supported here is 'path' which should be the top-level
      # directory where your mail currently exists and to where mail will be
      # delivered in the future. Files should be individual email messages.
      # Notmuch will store its database within a sub-directory of the path
      # configured here named ".notmuch".
      #
      [database]
      path=/var/vmail/diffeq.com/bct/mail
      # User configuration
      #
      # Here is where you can let notmuch know how you would like to be
      # addressed. Valid settings are
      #
      #	name		Your full name.
      #	primary_email	Your primary email address.
      #	other_email	A list (separated by ';') of other email addresses
      #			at which you receive email.
      #
      # Notmuch will use the various email addresses configured here when
      # formatting replies. It will avoid including your own addresses in the
      # recipient list of replies, and will set the From address based on the
      # address to which the original email was addressed.
      #
      [user]
      name=Brendan Taylor
      primary_email=bct@diffeq.com
      # Configuration for "notmuch new"
      #
      # The following options are supported here:
      #
      #	tags	A list (separated by ';') of the tags that will be
      #		added to all messages incorporated by "notmuch new".
      #
      #	ignore	A list (separated by ';') of file and directory names
      #		that will not be searched for messages by "notmuch new".
      #
      #		NOTE: *Every* file/directory that goes by one of those
      #		names will be ignored, independent of its depth/location
      #		in the mail store.
      #
      [new]
      tags=
      ignore=/(^|/)dovecot[-.]/;subscriptions
      # Search configuration
      #
      # The following option is supported here:
      #
      #	exclude_tags
      #		A ;-separated list of tags that will be excluded from
      #		search results by default.  Using an excluded tag in a
      #		query will override that exclusion.
      #
      [search]
      # Maildir compatibility configuration
      #
      # The following option is supported here:
      #
      #	synchronize_flags      Valid values are true and false.
      #
      #	If true, then the following maildir flags (in message filenames)
      #	will be synchronized with the corresponding notmuch tags:
      #
      #		Flag	Tag
      #		----	-------
      #		D	draft
      #		F	flagged
      #		P	passed
      #		R	replied
      #		S	unread (added when 'S' flag is not present)
      #
      #	The "notmuch new" command will notice flag changes in filenames
      #	and update tags, while the "notmuch tag" and "notmuch restore"
      #	commands will notice tag changes and update flags in filenames
      #
      [maildir]
    '';
  };
}
