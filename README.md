# dart_mail : command-line emailing utility

This is a command-line utility that takes a single file and can output a number of emails.

The email server settings of the *from* account are taken from environment variables for
security reasons.

## Input file format

Some of the lines of the input file have the format

        command ::~ value

Both the command and the value are trimmed of white spaces and the command is case-insensitive. 

The following commands are available:

    - to
    - cc
    - bcc
    - subject
    - attachment

The to,cc,bcc commands can take one or more email addresses seperated by semi-colons. These addresses are also space trimed.

## Error Handling

If there is an exception, the error is written to _stderr_ and the process terminates with a non-zero exit code. 

## Installation

The application can be compiled to a simple executable that can be run without installation. However, you do need to set up the following environment variables:

    - mail_server (smtp address)
    - mail_name (Robbie the mailbot)
    - mail_address (robbie@mail.bot)
    - privacy_token (i'm a cleartext password)

