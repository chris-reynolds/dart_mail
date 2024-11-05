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

// //   await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
// Future<void> driver2() async {
//   Map<String, String> env = Platform.environment;
//   fromServer = env['mail_server'] ?? '';
//   fromAddress = env['mail_address'] ?? '';
//   fromName = env['mail_name'] ?? '';
//   fromPassword = env['privacy_token'] ?? '';
//   if ([fromServer, fromAddress, fromName, fromPassword].contains('')) {
//     print('Environment variables not set up');
//     exit(16);
//   }
//   File pdfFile = File('./fred.pdf');
//   if (!pdfFile.existsSync()) {
//     throw 'pdf not found';
//   }
//   //Stream _stream;
//   final smtpServer = SmtpServer('mailx.freeparking.co.nz',
//       username: fromAddress, password: fromPassword, allowInsecure: true);

//   // Use the SmtpServer class to configure an SMTP server:
//   // final smtpServer = SmtpServer('smtp.domain.com');
//   // See the named arguments of SmtpServer for further configuration
//   // options.
//   var pdf = FileAttachment(pdfFile);
//   // Create our message.
//   final message = Message()
//     ..from = Address(fromAddress, fromName)
//     ..recipients.add('chrisr@instantobjects.com')
//     //  ..ccRecipients.addAll(['destCc1@example.com', 'destCc2@example.com'])
//     //   ..bccRecipients.add(Address('bccAddress@example.com'))
//     ..subject = 'Test Dart Mailer library :: 😀 :: ${DateTime.now()}'
//     ..attachments.add(pdf)
//     ..text = 'This is the plain text.\nThis is line 2 of the text part.'
//     ..html = "<h1>Test</h1>\n<p>Hey! Here's some HTML content</p>";

//   try {
//     final sendReport = await send(message, smtpServer);
//     print('Message sent: ${sendReport.toString()}');
//   } on MailerException catch (e) {
//     print('Message not sent.');
//     for (var p in e.problems) {
//       print('Problem: ${p.code}: ${p.msg}');
//     }
//   }
//   // DONE

//   // Let's send another message using a slightly different syntax:
//   //
//   // Addresses without a name part can be set directly.
//   // For instance `..recipients.add('destination@example.com')`
//   // If you want to display a name part you have to create an
//   // Address object: `new Address('destination@example.com', 'Display name part')`
//   // Creating and adding an Address object without a name part
//   // `new Address('destination@example.com')` is equivalent to
//   // adding the mail address as `String`.
//   final equivalentMessage = Message()
//     ..from = Address(fromAddress, fromName)
//     ..recipients.add(Address('chrisr@instantobjects.com'))
// //      ..ccRecipients.addAll([Address('destCc1@example.com'), 'destCc2@example.com'])
// //      ..bccRecipients.add('bccAddress@example.com')
//     ..subject = 'Test Dart Mailer library :: 😀 :: ${DateTime.now()}'
//     ..text = 'This is the plain text.\nThis is line 2 of the text part.'
//     ..html = "<h1>Test</h1>\n<p>Hey! Here's some HTML content</p>";

//   final sendReport2 = await send(equivalentMessage, smtpServer);
//   print('message2 sent $sendReport2');
//   // Sending multiple messages with the same connection
//   //
//   // Create a smtp client that will persist the connection
//   var connection = PersistentConnection(smtpServer);

//   // Send the first message
//   await connection.send(message);

//   // send the equivalent message
//   await connection.send(equivalentMessage);

//   // close the connection
//   await connection.close();
// }

// // class MailMessage {
// //   final String mailTo;
// //   String subject = 'none';
// //   String body = 'none';
// //   List<String> ccList = [];
// //   List<String> bccList = [];
// //   List<File> attachments = [];

// //   // constructor
// //   MailMessage(this.mailTo);
// //   Message assemble() {
// //     Message msg = Message()
// //       ..from = Address(fromAddress, fromName)
// //       ..recipients.addAll(mailTo.split(';'))
// //       ..subject = subject
// //       ..html = body;
// //     for (String cc in ccList) {
// //       msg.ccRecipients.add(Address(cc));
// //     }
// //     for (String bcc in bccList) {
// //       msg.ccRecipients.add(Address(bcc));
// //     }
// //     for (File f in attachments) {
// //       if (f.existsSync()) {
// //         msg.attachments.add(FileAttachment(f));
// //       }
// //     }
// //     return msg;
// //   } // of assemble
// // } // of send

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
        case 'file':
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
