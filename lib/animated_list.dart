import 'package:flutter/material.dart';

class CustomAnimatedList<T> extends StatefulWidget {
  CustomAnimatedList({super.key});
  final _listKey = GlobalKey<AnimatedListState>();
  final list = <T>[];

  int get length => list.length;

  void insert(T item) {
    list.insert(0, item);
    _listKey.currentState!.insertItem(0);
  }

  @override
  createState() => _AnimatedListState();
}
class _AnimatedListState extends State<CustomAnimatedList> {
  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      padding: const EdgeInsets.all(5),
      key: widget._listKey,
      initialItemCount: widget.list.length,
      itemBuilder: (c, index, animation) {
        final item = widget.list[index];
        return SizeTransition(
            sizeFactor: animation,
            child: Dismissible(
              key: Key(item.hashCode.toString()),
              // Add delete icon
              background: Card(child: Container(decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)))),
              direction: DismissDirection.endToStart,
              onDismissed: (d) {
                item.dispose();
                final index = widget.list.indexOf(item);
                widget.list.removeAt(index);
                widget._listKey.currentState!.removeItem(index, (c, a) => const SizedBox(width: 0, height: 0));
              },
              child: GestureDetector(
                onTap: () => item.onTap(context),
                child: Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: item.subtitle == null ? null : Text(item.subtitle!),
                  ),
                ),
              )
            )
        );
      },
    );
  }
}