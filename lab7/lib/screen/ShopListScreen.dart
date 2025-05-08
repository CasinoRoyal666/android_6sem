import 'package:flutter/material.dart';
import '../models/Shop.dart';
import '../database/databaseHelper.dart';
import '../screen/ShopDetailScreen.dart';
import '../screen/ShopEditScreen.dart';

class ShopListScreen extends StatefulWidget {
  @override
  _ShopListScreenState createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  List<Shop> shops = [];
  bool isLoading = true;
  String sortColumn = 'name';
  bool ascending = true;

  @override
  void initState() {
    super.initState();
    refreshShops();
  }

  Future refreshShops() async {
    setState(() => isLoading = true);

    shops = await DatabaseHelper.instance.getSortedShops(sortColumn, ascending);

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список магазинов'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (sortColumn == value) {
                  ascending = !ascending;
                } else {
                  sortColumn = value;
                  ascending = true;
                }
                refreshShops();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Text('Сортировать по названию ${sortColumn == 'name' ? (ascending ? '↑' : '↓') : ''}'),
              ),
              PopupMenuItem(
                value: 'rating',
                child: Text('Сортировать по рейтингу ${sortColumn == 'rating' ? (ascending ? '↑' : '↓') : ''}'),
              ),
              PopupMenuItem(
                value: 'category',
                child: Text('Сортировать по категории ${sortColumn == 'category' ? (ascending ? '↑' : '↓') : ''}'),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : shops.isEmpty
          ? Center(
        child: Text(
          'Нет магазинов',
          style: TextStyle(fontSize: 24),
        ),
      )
          : ListView.builder(
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];
          return ListTile(
            title: Text(shop.name),
            subtitle: Text('${shop.category} • Рейтинг: ${shop.rating}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ShopEditScreen(shop: shop),
                      ),
                    );
                    refreshShops();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Удалить магазин'),
                          content: Text('Вы уверены что хотите удалить "${shop.name}"?'),
                          actions: [
                            TextButton(
                              child: Text('Отмена'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: Text('Удалить'),
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteShop(shop.id!);
                                Navigator.of(context).pop();
                                refreshShops();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ShopDetailScreen(shopId: shop.id!),
                ),
              );
              refreshShops();
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ShopEditScreen(),
            ),
          );
          refreshShops();
        },
      ),
    );
  }
}