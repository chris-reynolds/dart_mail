import 'dart:io';
//import 'dart:async';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

late String fromServer;
late String fromName;
late String fromAddress;
late String fromPassword;
//late PersistentConnection conSmtp;

Future<void> driver(String fileName) async {
  try {
    File inputFile = File(fileName);
    SmtpServer smtpServer = setupServer();
    PersistentConnection conSmtp = PersistentConnection(smtpServer);
    if (!inputFile.existsSync()) throw 'Input file $inputFile is missing';
    List<Message> messagesToSend = loadLines(inputFile.readAsLinesSync());
    int messageIx = 0;
    for (Message thisMessage in messagesToSend) {
      messageIx++;
      try {
        final sendReport = await conSmtp.send(thisMessage);
        print('Message $messageIx sent: ${sendReport.toString()}');
      } on MailerException catch (e) {
        print('Message $messageIx not sent.');
        for (var p in e.problems) {
          print('Problem: ${p.code}: ${p.msg}');
        }
      }
    } // of for message loop
    await conSmtp.close();
  } catch (ex) {
    print(ex);
    stderr.write(ex);
    exit(16);
  }
}

SmtpServer setupServer() {
  Map<String, String> env = Platform.environment;
  fromServer = env['mail_server'] ?? '';
  fromAddress = env['mail_address'] ?? '';
  fromName = env['mail_name'] ?? '';
  fromPassword = env['privacy_token'] ?? '';
  if ([fromServer, fromAddress, fromName, fromPassword].contains('')) {
    print('Environment variables not set up');
    exit(16);
  }
  return SmtpServer(fromServer,
      username: fromAddress, password: fromPassword, allowInsecure: true);
}

List<Message> loadLines(Iterable<String> lines) {
  List<Message> result = [];
  Message? currentMessage;
  String detail = '';
  void flush() {
    if (currentMessage != null) result.add(currentMessage);
  }

  int lineIx = 0;
  try {
    for (String line in lines) {
      lineIx += 1;
      int delimpos = line.indexOf('::~');
      String command = '';
      String value = line.trim();
      if (delimpos > 0) {
        command = line.substring(0, delimpos).trim().toLowerCase();
        value = line.substring(delimpos + 3).trim();
      }
      switch (command) {
        case 'to':
          flush();
          currentMessage = Message()
            ..from = Address(fromAddress, fromName)
            ..html = '';
          for (String detail in value.split(';')) {
            currentMessage.recipients.add(Address(detail.trim()));
          }
        case 'subject':
          currentMessage!.subject = value;
        case 'cc':
          for (String detail in value.split(';')) {
            currentMessage!.ccRecipients.add(Address(detail.trim()));
          }
        case 'bcc':
          for (String detail in value.split(';')) {
            currentMessage!.bccRecipients.add(Address(detail.trim()));
          }
        case 'attachment' || 'file':
          for (String detail in value.split(';')) {
            detail = detail.trim();
            if (!File(detail).existsSync()) throw 'missing file $detail';
            currentMessage!.attachments.add(FileAttachment(File(detail)));
          }
        default:
          currentMessage!.html = '${currentMessage.html}$value\n';
      } // of switch
    } // of line loop
    flush();
    return result;
  } catch (ex) {
    print('Error in line $lineIx : $ex (detail may be $detail)');
    rethrow;
  } // of try
} // of loadLines
