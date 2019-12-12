import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cupertino_date_picker/flutter_cupertino_date_picker.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pixez/component/illust_card.dart';
import 'package:pixez/network/api_client.dart';
import 'package:pixez/page/search/result/bloc/bloc.dart';

class SearchResultPage extends StatefulWidget {
  final String word;

  const SearchResultPage({Key key, this.word}) : super(key: key);

  @override
  _SearchResultPageState createState() => _SearchResultPageState();
}

class MaterialHeader extends Header {
  @override
  Widget contentBuilder(
      BuildContext context,
      RefreshMode refreshState,
      double pulledExtent,
      double refreshTriggerPullDistance,
      double refreshIndicatorExtent,
      AxisDirection axisDirection,
      bool float,
      Duration completeDuration,
      bool enableInfiniteRefresh,
      bool success,
      bool noMore) {
    // TODO: implement contentBuilder
    return Container(
      child: Text("Pick"),
    );
  }
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  EasyRefreshController _refreshController;
  Completer<void> _refreshCompleter, _loadCompleter;
  GlobalKey<ScaffoldState> _scaffoldStateKey;

  @override
  void initState() {
    super.initState();
    _scaffoldStateKey = GlobalKey<ScaffoldState>();
    _refreshCompleter = Completer<void>();
    _loadCompleter = Completer<void>();
    _tabController = TabController(vsync: this, length: 2);
    _refreshController = EasyRefreshController();
  }

  String _sortValue = "date_desc";
  String _searchTargetValue = "partial_match_for_tags";
  bool enableDuration = false;
  DateTime startDate = DateTime.now(),
      endDate = DateTime.now();

  EasyRefresh _buildEasyRefresh(DataState state, BuildContext context) {
    return EasyRefresh(
      controller: _refreshController,
      child: StaggeredGridView.countBuilder(
        crossAxisCount: 2,
        itemCount: state.illusts.length,
        itemBuilder: (context, index) {
          return IllustCard(state.illusts[index]);
        },
        staggeredTileBuilder: (int index) => StaggeredTile.fit(1),
      ),
      onRefresh: () async {
        BlocProvider.of<SearchResultBloc>(context).add(FetchEvent(
            widget.word,
            _sortValue,
            _searchTargetValue,
            startDate,
            endDate,
            enableDuration));
        return _refreshCompleter.future;
      },
      onLoad: () async {
        BlocProvider.of<SearchResultBloc>(context)
            .add(LoadMoreEvent(state.nextUrl, state.illusts));
        return _loadCompleter.future;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      SearchResultBloc(ApiClient())
        ..add(FetchEvent(widget.word, _sortValue, _searchTargetValue, startDate,
            endDate, enableDuration)),
      child: BlocBuilder<SearchResultBloc, SearchResultState>(
        builder: (context, state) {
          if (state is DataState)
            return Scaffold(
              appBar: _buildAppBar(context),
              body: BlocListener<SearchResultBloc, SearchResultState>(
                  listener: (context, state) {
                    if (state is DataState) {
                      _loadCompleter?.complete();
                      _loadCompleter = Completer();
                      _refreshCompleter?.complete();
                      _refreshCompleter = Completer();
                    }
                  },
                  child: _buildEasyRefresh(state, context)),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: Icon(Icons.sort),
              ),
            );
          else
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
        },
      ),
    );
  }

  final starnum = [50000, 30000, 20000, 10000, 5000, 1000, 500, 250, 100, 0];
  final sort = ["date_desc", "date_asc", "popular_desc"];
  var search_target = [
    "partial_match_for_tags",
    "exact_match_for_tags",
    "title_and_caption"
  ];

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.word),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () {
            showModalBottomSheet<void>(
                context: context,
                builder: (_) {
                  return StatefulBuilder(builder: (_, setBottomSheetState) {
                    if (startDate.isAfter(endDate)) {
                      startDate = DateTime.now();
                      endDate = DateTime.now();
                    }
                    return Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              ...sort
                                  .map((f) =>
                                  Flexible(
                                    child: RadioListTile<String>(
                                      value: f,
                                      title: Text(f),
                                      groupValue: _sortValue,
                                      onChanged: (value) {
                                        setBottomSheetState(() {
                                          _sortValue = value;
                                        });
                                      },
                                    ),
                                  ))
                                  .toList(),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              ...search_target
                                  .map((f) =>
                                  Flexible(
                                    child: RadioListTile<String>(
                                      value: f,
                                      title: Text(f),
                                      groupValue: _searchTargetValue,
                                      onChanged: (value) {
                                        setBottomSheetState(() {
                                          _searchTargetValue = value;
                                        });
                                      },
                                    ),
                                  ))
                                  .toList(),
                            ],
                          ),
                          SwitchListTile(
                              title: Text("Duration"),
                              value: enableDuration,
                              onChanged: (v) {
                                setBottomSheetState(() {
                                  enableDuration = v;
                                });
                              }),
                          Visibility(
                            child: Row(
                              children: <Widget>[
                                OutlineButton(
                                  onPressed: () {
                                    DatePicker.showDatePicker(context,
                                        maxDateTime: endDate,
                                        initialDateTime: startDate, onConfirm:
                                            (DateTime dateTime,
                                            List<int> list) {
                                          setBottomSheetState(() {
                                            startDate = dateTime;
                                          });
                                          setState(() {
                                            startDate = dateTime;
                                          });
                                        });
                                  },
                                  child: Text(startDate
                                      .toIso8601String()
                                      .split("T")[0]), //AXAXAX
                                ),
                                Text("~"),
                                OutlineButton(
                                  onPressed: () {
                                    DatePicker.showDatePicker(context,
                                        maxDateTime: DateTime.now(),
                                        initialDateTime: endDate, onConfirm:
                                            (DateTime dateTime,
                                            List<int> list) {
                                          setBottomSheetState(() {
                                            endDate = dateTime;
                                          });
                                          setState(() {
                                            endDate = dateTime;
                                          });
                                        });
                                  },
                                  child: Text(
                                      endDate.toIso8601String().split("T")[0]),
                                ),
                              ],
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                            ),
                            visible: enableDuration,
                          ),
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: RaisedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                BlocProvider.of<SearchResultBloc>(context).add(
                                    ApplyEvent(
                                        widget.word,
                                        _sortValue,
                                        _searchTargetValue,
                                        startDate,
                                        endDate,
                                        enableDuration));
                              },
                              child: Text("Apply"),
                              color: Theme
                                  .of(context)
                                  .primaryColor,
                              textColor: Colors.white,
                            ),
                          )
                        ],
                      ),
                    );
                  });
                });
          },
        )
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: <Widget>[
          Tab(
            child: Text("Illust"),
          ),
          Tab(
            child: Text("Illust"),
          ),
        ],
      ),
    );
  }
}
