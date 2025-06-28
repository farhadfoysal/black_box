import 'package:flutter/material.dart';

import '../../../../model/history_model.dart';

class HistoryWidget extends StatelessWidget {
  final HistoryModel history;

  const HistoryWidget({
    Key? key,
    required this.history,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            history.date,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill Number',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    history.billNumber,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consumptions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    history.consumptions,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                '৳${history.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
