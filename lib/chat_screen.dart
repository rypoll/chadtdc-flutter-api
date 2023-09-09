import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'chatmessage.dart';
import 'threedots.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  late OpenAI? chatGPT;
  final http.Client client = http.Client();
  late Dio dio;
  late CookieJar cookieJar;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    dio = Dio();
    cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));
    chatGPT = OpenAI.instance.build(
        token: dotenv.env["API_KEY"],
        baseOption: HttpSetup(receiveTimeout: Duration(milliseconds: 60000)));
  }

  @override
  void dispose() {
    chatGPT?.close();
    chatGPT?.genImgClose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    ChatMessage message = ChatMessage(
      text: _controller.text,
      sender: "user",
      isImage: false,
    );

    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    _controller.clear();

    var url = 'https://chad-tdc.nw.r.appspot.com/api/chat';
    var data = {'in-0': message.text};

    var response = await dio.post(url, data: json.encode(data), options: Options(
      contentType: Headers.jsonContentType,
    ));

    if (response.statusCode == 200) {
      var decodedResponse = response.data;
      String botResponse = decodedResponse['out-0'];
      insertNewData(botResponse, isImage: false);
      List<Cookie> cookies = await cookieJar.loadForRequest(Uri.parse('https://chad-tdc.nw.r.appspot.com/'));
      print("Stored Cookies: $cookies");
    } else {
      print('Failed to send message: ${response.statusCode}');
    }
  }

  void insertNewData(String response, {bool isImage = false}) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "bot",
      isImage: isImage,
    );

    setState(() {
      _isTyping = false;
      _messages.insert(0, botMessage);
    });
  }

  Widget _buildTextComposer() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (value) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Type your message",
                filled: true,
                fillColor: Color(0xFF101112),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(60),
                  borderSide: BorderSide(color: Color(0xFF20699d)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(60),
                  borderSide: BorderSide(color: Color(0xFF20699d)),
                ),
              ),
            ),
          ),
          SizedBox(width: 25),
          CircleAvatar(
            backgroundColor: Color(0xFF20699d),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("ChadTDC - The Date Coach"),
        backgroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.zero,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _messages[index];
                },
              ),
            ),
            if (_isTyping) const ThreeDots(),
            const Divider(height: 1.0),
            Container(
              color: Color(0xFF101112),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }
}
