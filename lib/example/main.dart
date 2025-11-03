import 'package:flutter/material.dart';
import 'package:flutter_pagination_helper/flutter_pagination_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagination Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ProductListPage(),
    );
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage>
    with PaginationMixin {
  ProductData data = ProductData.empty();
  bool isLoadingMore = false;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    await loadMoreData<ProductData>(
      fetchData: (offset, limit) async {
        await Future.delayed(const Duration(seconds: 1));

        final products = List.generate(
          limit,
          (index) => Product(
            id: offset + index + 1,
            name: 'Product ${offset + index + 1}',
            description: 'Description for product ${offset + index + 1}',
            price: (offset + index + 1) * 9.99,
          ),
        );

        const totalProducts = 50;

        return ProductData(
          products: products,
          total: totalProducts,
        );
      },
      mergeData: (current, newData) => current.copyWith(
        products: [...current.products, ...newData.products],
        total: newData.total,
      ),
      getCurrentCount: (d) => d.products.length,
      getTotalCount: (d) => d.total,
      updateState: (loading, newData, err) {
        setState(() {
          isLoadingMore = loading;
          if (newData != null) {
            data = newData;
            isLoading = false;
          }
          error = err;
        });
      },
      currentData: data,
      isCurrentlyLoading: isLoadingMore,
      limit: 10,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      data = ProductData.empty();
      isLoadingMore = false;
      isLoading = true;
      error = null;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && data.products.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Builder(
        builder: (context) {
          if (error != null && data.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return PaginatedListView<Product>(
            items: data.products,
            isLoadingMore: isLoadingMore,
            onRefresh: _refresh,
            onLoadMore: _loadMore,
            itemBuilder: (context, product, index) {
              return ProductCard(product: product);
            },
            padding: const EdgeInsets.all(16.0),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            product.name[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(product.name),
        subtitle: Text(product.description),
        trailing: Text(
          '\${product.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// MODELS
class ProductData {
  final List<Product> products;
  final int total;

  ProductData({required this.products, required this.total});

  factory ProductData.empty() => ProductData(products: [], total: 0);

  ProductData copyWith({List<Product>? products, int? total}) {
    return ProductData(
      products: products ?? this.products,
      total: total ?? this.total,
    );
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });
}
