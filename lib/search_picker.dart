import 'package:flutter/material.dart';

import 'api.dart';
import 'sales_theme.dart';
import 'tablet_filter_panel.dart';

class SearchPicker<T> extends StatefulWidget {
  const SearchPicker({
    super.key,
    required this.title,
    required this.hint,
    required this.load,
    required this.label,
    required this.code,
    this.empty,
    this.thumbnail,
  });

  final String title;
  final String hint;
  final Future<({List<T> items, bool hasNext})> Function(String, int) load;
  final String Function(T) label;
  final String Function(T) code;
  final String? empty;
  final Widget Function(T)? thumbnail;

  @override
  State<SearchPicker<T>> createState() => _SearchPickerState<T>();
}

class _SearchPickerState<T> extends State<SearchPicker<T>> {
  final _input = TextEditingController();
  late Future<({List<T> items, bool hasNext})> _results;
  String _query = '';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _results = widget.load(_query, _page);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _load(String query, int page) => setState(() {
    _query = query;
    _page = page;
    _results = widget.load(query, page);
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: widget.thumbnail == null ? 490 : 690,
      height: 330,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: InputDecoration(hintText: widget.hint),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => _load(value.trim(), 1),
                ),
              ),
              const SizedBox(width: 8),
              TabletAction(
                '查询',
                primary: true,
                onPressed: () => _load(_input.text.trim(), 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error is ApiFailure ? error.message : '连接失败，请检查网络。',
                        ),
                        const SizedBox(height: 8),
                        TabletAction(
                          '重试',
                          onPressed: () => _load(_query, _page),
                        ),
                      ],
                    ),
                  );
                }
                final result = snapshot.requireData;
                return Column(
                  children: [
                    Expanded(
                      child: result.items.isEmpty
                          ? Center(
                              child: Text(
                                (_query.isEmpty ? widget.empty : null) ??
                                    '没有符合条件的资料',
                              ),
                            )
                          : widget.thumbnail != null
                          ? LayoutBuilder(
                              builder: (context, constraints) => GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          (constraints.maxWidth / 212)
                                              .floor()
                                              .clamp(1, 3),
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      mainAxisExtent: 69,
                                    ),
                                itemCount: result.items.length,
                                itemBuilder: (context, index) {
                                  final item = result.items[index];
                                  return Material(
                                    color: salesPaper,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: salesLine),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => Navigator.pop(context, item),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          children: [
                                            widget.thumbnail!(item),
                                            const SizedBox(width: 9),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    widget.label(item),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    widget.code(item),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: salesMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : ListView.builder(
                              itemCount: result.items.length,
                              itemBuilder: (context, index) {
                                final item = result.items[index];
                                return ListTile(
                                  title: Text(widget.label(item)),
                                  subtitle: Text(widget.code(item)),
                                  onTap: () => Navigator.pop(context, item),
                                );
                              },
                            ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _page > 1
                              ? () => _load(_query, _page - 1)
                              : null,
                          child: const Text('上一页'),
                        ),
                        TextButton(
                          onPressed: result.hasNext
                              ? () => _load(_query, _page + 1)
                              : null,
                          child: const Text('下一页'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
    ],
  );
}
