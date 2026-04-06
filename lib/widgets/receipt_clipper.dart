import 'package:flutter/material.dart';

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);

    // Zig zag at the top
    double width = 15;
    double height = 8;
    int count = (size.width / width).floor();

    for (int i = 0; i < count; i++) {
      if (i % 2 == 0) {
        path.lineTo(size.width - (i * width), height);
      } else {
        path.lineTo(size.width - (i * width), 0);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ReceiptPaperClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    // Start with zig-zag at the top
    double width = 20.0;
    double height = 10.0;
    int n = (size.width / width).floor();
    
    path.moveTo(0, height);
    for (int i = 1; i <= n; i++) {
      if (i % 2 != 0) {
        path.lineTo(width * i, 0);
      } else {
        path.lineTo(width * i, height);
      }
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
