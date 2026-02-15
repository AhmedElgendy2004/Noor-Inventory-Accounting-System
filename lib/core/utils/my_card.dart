import 'package:flutter/material.dart';

class MyCard extends StatelessWidget {
  const MyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("ENG / Ahmed Elgendy \n for software solutions"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                " 01027772838  ",
                style: TextStyle(color: Colors.green),
              ),
              Image.asset("assets/image/whatsapp (2).png"),
            ],
          ),
        ],
      ),
    );
  }
}
