# 📦 Flutter Pagination Helper

[![pub package](https://img.shields.io/pub/v/pagination_helper.svg)](https://pub.dev/packages/pagination_helper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev)

A lightweight and **state-management-agnostic** Flutter package for implementing pagination with minimal boilerplate. Works with **ANY** state management solution: Cubit, Bloc, Provider, Riverpod, GetX, setState, and more!

## 🎯 Why Choose This Package?

- ✅ **Zero Framework Dependencies** - Works with any state management
- ✅ **Minimal Boilerplate** - Get pagination working in minutes
- ✅ **Type-Safe** - Fully generic implementation
- ✅ **Flexible** - Supports offset, page, and cursor-based pagination
- ✅ **Production Ready** - Battle-tested and well-maintained
- ✅ **Customizable** - Highly configurable for your needs

## 📋 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Basic Usage](#-basic-usage)
- [State Management Examples](#-state-management-examples)
  - [Flutter Bloc/Cubit](#1-flutter-bloccubit)
  - [Provider/ChangeNotifier](#2-providerchangenotifier)
  - [Riverpod](#3-riverpod)
  - [GetX](#4-getx)
  - [setState](#5-setstate-statefulwidget)
- [Advanced Features](#-advanced-features)
  - [Pagination Types](#pagination-types)
  - [Error Handling](#error-handling)
  - [Customization](#customization)
- [API Reference](#-api-reference)
- [Common Patterns](#-common-patterns)
- [Requirements](#-requirements)
- [Contributing](#-contributing)

## ✨ Features

- 🔄 **Universal Compatibility**: Works with ANY state management (Cubit, Bloc, Provider, Riverpod, GetX, setState)
- 📜 **PaginatedListView**: Automatic infinite scrolling list with pull-to-refresh
- 📊 **PaginatedGridView**: Grid layout with pagination support
- 🧩 **PaginationMixin**: Powerful mixin with zero framework dependencies
- 🔀 **Flexible Pagination**: Supports offset-based, page-based, and cursor-based pagination
- 🎨 **Customizable**: Loading indicators, empty states, thresholds, separators, and more
- 🛡️ **Type-Safe**: Fully generic implementation for better code safety

## 📥 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  pagination_helper: ^latest_version
```

Then run:

```bash
flutter pub get
```

Import the package:

```dart
import 'package:pagination_helper/pagination_helper.dart';
```

## 🚀 Quick Start

### Step 1: Add the Widget

Replace your `ListView` with `PaginatedListView`:

```dart
PaginatedListView<Product>(
  items: products,                    // Your list from state management
  isLoadingMore: isLoadingMore,       // Loading flag from your state
  onLoadMore: () => loadMore(),       // Callback to load more items
  onRefresh: () => refresh(),         // Optional: pull-to-refresh callback
  itemBuilder: (context, product, index) {
    return ListTile(
      title: Text(product.name),
      subtitle: Text('${product.price}'),
    );
  },
  emptyWidget: const Center(
    child: Text('No products found'),
  ),
)
```

### Step 2: Use PaginationMixin

Add the mixin to your state management class and implement `loadMore()`:

```dart
class ProductCubit extends Cubit<ProductState> with PaginationMixin {
  Future<void> loadMore() async {
    await loadMoreData<ProductData>(
      fetchData: (offset, limit) async {
        return await apiService.getProducts(skip: offset, limit: limit);
      },
      mergeData: (current, newData) => current.copyWith(
        products: [...current.products, ...newData.products],
        total: newData.total,
      ),
      getCurrentCount: (data) => data.products.length,
      getTotalCount: (data) => data.total,
      updateState: (isLoading, data, error) {
        emit(state.copyWith(
          data: data ?? state.data,
          isLoadingMore: isLoading,
          error: error,
        ));
      },
      currentData: state.data,
      isCurrentlyLoading: state.isLoadingMore,
    );
  }
}
```

That's it! Your pagination is now working. 🎉

## 📖 Basic Usage

### Simple List View

The simplest way to use pagination:

```dart
PaginatedListView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  onLoadMore: () => controller.loadMore(),
  itemBuilder: (context, product, index) {
    return ProductCard(product: product);
  },
)
```

### With Pull-to-Refresh

```dart
PaginatedListView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  onLoadMore: () => controller.loadMore(),
  onRefresh: () => controller.refresh(),  // Enables pull-to-refresh
  itemBuilder: (context, product, index) => ProductCard(product: product),
)
```

### Grid View

Perfect for product catalogs, image galleries, and more:

```dart
PaginatedGridView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  onLoadMore: () => controller.loadMore(),
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: 0.7,
  itemBuilder: (context, product, index) {
    return ProductGridCard(product: product);
  },
)
```

## 🎯 State Management Examples

Choose your preferred state management solution:

### 1. Flutter Bloc/Cubit

**Complete Example:**

```dart
// State
class ProductState {
  final ProductData data;
  final bool isLoadingMore;
  final String? error;

  ProductState({
    required this.data,
    required this.isLoadingMore,
    this.error,
  });

  ProductState copyWith({
    ProductData? data,
    bool? isLoadingMore,
    String? error,
  }) {
    return ProductState(
      data: data ?? this.data,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }

  static ProductState initial() => ProductState(
    data: ProductData.empty(),
    isLoadingMore: false,
  );

  List<Product> get products => data.products;
}

// Cubit
class ProductCubit extends Cubit<ProductState> with PaginationMixin {
  final ApiService apiService;
  
  ProductCubit({required this.apiService}) 
    : super(ProductState.initial());

  Future<void> loadMore() async {
    await loadMoreData<ProductData>(
      fetchData: (offset, limit) async {
        return await apiService.getProducts(skip: offset, limit: limit);
      },
      mergeData: (current, newData) => current.copyWith(
        products: [...current.products, ...newData.products],
        total: newData.total,
      ),
      getCurrentCount: (data) => data.products.length,
      getTotalCount: (data) => data.total,
      updateState: (isLoading, data, error) {
        if (error != null) {
          emit(state.copyWith(isLoadingMore: false, error: error));
        } else if (data != null) {
          emit(state.copyWith(
            data: data,
            isLoadingMore: isLoading,
            error: null,
          ));
        } else {
          emit(state.copyWith(isLoadingMore: isLoading));
        }
      },
      currentData: state.data,
      isCurrentlyLoading: state.isLoadingMore,
    );
  }

  Future<void> refresh() async {
    emit(ProductState.initial());
    await loadMore();
  }
}

// Usage in Widget
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        return PaginatedListView<Product>(
          items: state.products,
          isLoadingMore: state.isLoadingMore,
          onRefresh: () => context.read<ProductCubit>().refresh(),
          onLoadMore: () => context.read<ProductCubit>().loadMore(),
          itemBuilder: (context, product, index) => ProductCard(product),
          emptyWidget: state.error != null 
            ? ErrorWidget(error: state.error!) 
            : null,
        );
      },
    );
  }
}
```

### 2. Provider/ChangeNotifier

```dart
class ProductProvider with ChangeNotifier, PaginationMixin {
  final ApiService apiService;
  
  ProductProvider({required this.apiService});

  ProductData _data = ProductData.empty();
  bool _isLoadingMore = false;
  String? _error;

  // Getters
  ProductData get data => _data;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<Product> get products => _data.products;

  Future<void> loadMore() async {
    await loadMoreData<ProductData>(
      fetchData: (offset, limit) async {
        return await apiService.getProducts(skip: offset, limit: limit);
      },
      mergeData: (current, newData) => current.copyWith(
        products: [...current.products, ...newData.products],
        total: newData.total,
      ),
      getCurrentCount: (data) => data.products.length,
      getTotalCount: (data) => data.total,
      updateState: (isLoading, data, error) {
        _isLoadingMore = isLoading;
        if (data != null) _data = data;
        if (error != null) _error = error;
        notifyListeners();
      },
      currentData: _data,
      isCurrentlyLoading: _isLoadingMore,
    );
  }

  Future<void> refresh() async {
    _data = ProductData.empty();
    _isLoadingMore = false;
    _error = null;
    notifyListeners();
    await loadMore();
  }
}

// Usage
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return PaginatedListView<Product>(
          items: provider.products,
          isLoadingMore: provider.isLoadingMore,
          onRefresh: () => provider.refresh(),
          onLoadMore: () => provider.loadMore(),
          itemBuilder: (context, product, index) => ProductCard(product),
        );
      },
    );
  }
}
```

### 3. Riverpod

```dart
// State
class ProductState {
  final ProductData data;
  final bool isLoadingMore;
  final String? error;

  ProductState({
    required this.data,
    required this.isLoadingMore,
    this.error,
  });

  ProductState copyWith({
    ProductData? data,
    bool? isLoadingMore,
    String? error,
  }) {
    return ProductState(
      data: data ?? this.data,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }

  static ProductState initial() => ProductState(
    data: ProductData.empty(),
    isLoadingMore: false,
  );
}

// Notifier
class ProductNotifier extends StateNotifier<ProductState> 
    with PaginationMixin {
  ProductNotifier(this.apiService) : super(ProductState.initial());
  
  final ApiService apiService;

  Future<void> loadMore() async {
    await loadMoreData<ProductData>(
      fetchData: (offset, limit) async {
        return await apiService.getProducts(skip: offset, limit: limit);
      },
      mergeData: (current, newData) => current.copyWith(
        products: [...current.products, ...newData.products],
        total: newData.total,
      ),
      getCurrentCount: (data) => data.products.length,
      getTotalCount: (data) => data.total,
      updateState: (isLoading, data, error) {
        state = state.copyWith(
          isLoadingMore: isLoading,
          data: data ?? state.data,
          error: error,
        );
      },
      currentData: state.data,
      isCurrentlyLoading: state.isLoadingMore,
    );
  }

  Future<void> refresh() async {
    state = ProductState.initial();
    await loadMore();
  }
}

// Provider
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>(
  (ref) => ProductNotifier(ref.watch(apiServiceProvider))..loadMore(),
);

// Usage
class ProductListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider);
    final notifier = ref.read(productProvider.notifier);
    
    return PaginatedListView<Product>(
      items: state.data.products,
      isLoadingMore: state.isLoadingMore,
      onRefresh: () => notifier.refresh(),
      onLoadMore: () => notifier.loadMore(),
      itemBuilder: (context, product, index) => ProductCard(product),
    );
  }
}
```

### 4. GetX

```dart
class ProductController extends GetxController with PaginationMixin {
  final ApiService apiService;
  
  ProductController({required this.apiService});

  final products = <Product>[].obs;
  final isLoadingMore = false.obs;
  final total = 0.obs;
  final error = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    loadMore();
  }

  Future<void> loadMore() async {
    final currentData = ProductData(
      products: products.toList(),
      total: total.value,
    );

    await loadMoreData<ProductData>(
      fetchData: (offset, limit) async {
        return await apiService.getProducts(skip: offset, limit: limit);
      },
      mergeData: (current, newData) => ProductData(
        products: [...current.products, ...newData.products],
        total: newData.total,
      ),
      getCurrentCount: (data) => data.products.length,
      getTotalCount: (data) => data.total,
      updateState: (isLoading, data, err) {
        isLoadingMore.value = isLoading;
        if (data != null) {
          products.value = data.products;
          total.value = data.total;
        }
        if (err != null) error.value = err;
      },
      currentData: currentData,
      isCurrentlyLoading: isLoadingMore.value,
    );
  }

  Future<void> refresh() async {
    products.clear();
    total.value = 0;
    isLoadingMore.value = false;
    error.value = null;
    await loadMore();
  }
}

// Usage
class ProductListPage extends StatelessWidget {
  final controller = Get.put(ProductController(
    apiService: Get.find<ApiService>(),
  ));

  @override
  Widget build(BuildContext context) {
    return Obx(() => PaginatedListView<Product>(
      items: controller.products,
      isLoadingMore: controller.isLoadingMore.value,
      onRefresh: () => controller.refresh(),
      onLoadMore: () => controller.loadMore(),
      itemBuilder: (context, product, index) => ProductCard(product),
    ));
  }
}
```

### 5. setState (StatefulWidget)

Perfect for simple apps without state management:

```dart
class ProductListPage extends StatefulWidget {
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> 
    with PaginationMixin {
  final ApiService apiService = ApiService();
  
  List<Product> products = [];
  bool isLoadingMore = false;
  int total = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    loadMore();
  }

  Future<void> loadMore() async {
    final currentData = ProductData(products: products, total: total);

    await loadMoreData<ProductData>(
      fetchData: (offset, limit) async {
        return await apiService.getProducts(skip: offset, limit: limit);
      },
      mergeData: (current, newData) => ProductData(
        products: [...current.products, ...newData.products],
        total: newData.total,
      ),
      getCurrentCount: (data) => data.products.length,
      getTotalCount: (data) => data.total,
      updateState: (isLoading, data, err) {
        setState(() {
          isLoadingMore = isLoading;
          if (data != null) {
            products = data.products;
            total = data.total;
          }
          if (err != null) error = err;
        });
      },
      currentData: currentData,
      isCurrentlyLoading: isLoadingMore,
    );
  }

  Future<void> refresh() async {
    setState(() {
      products = [];
      total = 0;
      isLoadingMore = false;
      error = null;
    });
    await loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return PaginatedListView<Product>(
      items: products,
      isLoadingMore: isLoadingMore,
      onRefresh: refresh,
      onLoadMore: loadMore,
      itemBuilder: (context, product, index) => ProductCard(product: product),
    );
  }
}
```

## 🚀 Advanced Features

### Pagination Types

#### Offset-Based Pagination (Default)

Most common type. Uses skip/offset parameters:

```dart
await loadMoreData<ProductData>(
  fetchData: (offset, limit) async {
    // offset: 0, 10, 20, 30...
    // Return data or throw error
    return await api.getProducts(skip: offset, limit: limit);
  },
  mergeData: (current, newData) => current.copyWith(
    products: [...current.products, ...newData.products],
  ),
  getCurrentCount: (data) => data.products.length,
  getTotalCount: (data) => data.total,
  updateState: (isLoading, data, error) {
    // Update your state here
  },
  currentData: yourCurrentData,
  isCurrentlyLoading: yourLoadingFlag,
);
```

#### Page-Based Pagination

Uses page numbers starting from 1:

```dart
await loadMoreWithPage<ProductData>(
  fetchData: (page, limit) async {
    // page: 1, 2, 3, 4...
    return await api.getProducts(page: page, limit: limit);
  },
  mergeData: (current, newData) => current.copyWith(
    products: [...current.products, ...newData.products],
  ),
  getCurrentCount: (data) => data.products.length,
  getTotalCount: (data) => data.total,
  updateState: (isLoading, data, error) {
    // Update your state here
  },
  currentData: yourCurrentData,
  isCurrentlyLoading: yourLoadingFlag,
);
```

#### Cursor-Based Pagination

Perfect for real-time data and infinite feeds:

```dart
await loadMoreWithCursor<ProductData>(
  fetchData: (cursor, limit) async {
    // cursor: null, "cursor1", "cursor2"...
    return await api.getProducts(cursor: cursor, limit: limit);
  },
  mergeData: (current, newData) => current.copyWith(
    products: [...current.products, ...newData.products],
  ),
  getNextCursor: (data) => data.nextCursor,  // Extract cursor from response
  hasMoreData: (data) => data.nextCursor != null,  // Check if more available
  updateState: (isLoading, data, error) {
    // Update your state here
  },
  currentData: yourCurrentData,
  isCurrentlyLoading: yourLoadingFlag,
);
```

### Error Handling

The mixin automatically catches errors from `fetchData`. Handle them in `updateState`:

```dart
await loadMoreData<ProductData>(
  fetchData: (offset, limit) async {
    try {
      return await api.getProducts(skip: offset, limit: limit);
    } catch (e) {
      // Mixin will catch and pass to updateState
      throw Exception('Failed to load products: $e');
    }
  },
  updateState: (isLoading, data, error) {
    if (error != null) {
      // Handle error in your state
      emit(state.copyWith(error: error));
      // Show error to user
      showErrorSnackbar(error);
    } else if (data != null) {
      // Handle success
      emit(state.copyWith(data: data));
    }
    emit(state.copyWith(isLoadingMore: isLoading));
  },
  // Optional: Additional error callback
  onError: (error) {
    print('Pagination error: $error');
    // Log to analytics, etc.
  },
);
```

### Customization

#### Custom Loading Widget

```dart
PaginatedListView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  onLoadMore: () => cubit.loadMore(),
  itemBuilder: (context, product, index) => ProductCard(product),
  loadingWidget: const Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 8),
        Text('Loading more products...'),
      ],
    ),
  ),
)
```

#### Custom Load More Threshold

Control when to trigger loading (distance from bottom in pixels):

```dart
PaginatedListView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  loadMoreThreshold: 500.0,  // Trigger 500px before bottom
  onLoadMore: () => cubit.loadMore(),
  itemBuilder: (context, product, index) => ProductCard(product),
)
```

#### With Separators

Add dividers or custom separators between items:

```dart
PaginatedListView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  onLoadMore: () => cubit.loadMore(),
  itemBuilder: (context, product, index) => ProductCard(product),
  separatorBuilder: (context, index) => const Divider(height: 1),
)
```

#### Custom Empty State

Show custom widget when list is empty:

```dart
PaginatedListView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  onLoadMore: () => cubit.loadMore(),
  itemBuilder: (context, product, index) => ProductCard(product),
  emptyWidget: const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('No products found'),
        SizedBox(height: 8),
        Text('Pull down to refresh'),
      ],
    ),
  ),
)
```

#### Disable Pull-to-Refresh

```dart
PaginatedListView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  onLoadMore: () => cubit.loadMore(),
  enableRefresh: false,  // Disable pull-to-refresh
  itemBuilder: (context, product, index) => ProductCard(product),
)
```

## 📚 Common Patterns

### Data Model Structure

Your data model should include the list of items and total count:

```dart
class ProductData {
  final List<Product> products;
  final int total;

  ProductData({
    required this.products,
    required this.total,
  });

  ProductData copyWith({
    List<Product>? products,
    int? total,
  }) {
    return ProductData(
      products: products ?? this.products,
      total: total ?? this.total,
    );
  }

  static ProductData empty() => ProductData(products: [], total: 0);
}
```

### API Service Example

```dart
class ApiService {
  Future<ProductData> getProducts({
    required int skip,
    required int limit,
  }) async {
    final response = await http.get(
      Uri.parse('https://api.example.com/products?skip=$skip&limit=$limit'),
    );
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ProductData(
        products: (json['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList(),
        total: json['total'],
      );
    } else {
      throw Exception('Failed to load products');
    }
  }
}
```

### Loading Initial Data

Always load initial data when the screen opens:

```dart
@override
void initState() {
  super.initState();
  // Load first page
  loadMore();
}

// Or in Cubit constructor
ProductCubit({required this.apiService}) 
  : super(ProductState.initial()) {
  loadMore();  // Load initial data
}
```

## 📖 API Reference

### PaginatedListView\<T\>

A list view widget with built-in pagination support.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `items` | `List<T>` | ✅ Yes | - | List of items to display |
| `isLoadingMore` | `bool` | ✅ Yes | - | Whether currently loading more items |
| `itemBuilder` | `Widget Function(BuildContext, T, int)` | ✅ Yes | - | Builder for individual items |
| `onLoadMore` | `VoidCallback` | ✅ Yes | - | Called when more items are needed |
| `onRefresh` | `Future<void> Function()?` | ❌ No | `null` | Pull-to-refresh callback |
| `loadingWidget` | `Widget?` | ❌ No | Default indicator | Custom loading indicator |
| `emptyWidget` | `Widget?` | ❌ No | `null` | Widget shown when list is empty |
| `loadMoreThreshold` | `double` | ❌ No | `200.0` | Distance from bottom to trigger load (in pixels) |
| `separatorBuilder` | `Widget Function(BuildContext, int)?` | ❌ No | `null` | Builder for item separators |
| `enableRefresh` | `bool` | ❌ No | `true` | Enable pull-to-refresh functionality |

### PaginatedGridView\<T\>

A grid view widget with built-in pagination support.

**Inherits all parameters from PaginatedListView plus:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `crossAxisCount` | `int` | ✅ Yes | - | Number of columns in the grid |
| `childAspectRatio` | `double` | ❌ No | `1.0` | Width/height ratio of each child |
| `crossAxisSpacing` | `double` | ❌ No | `0.0` | Horizontal spacing between items |
| `mainAxisSpacing` | `double` | ❌ No | `0.0` | Vertical spacing between items |

### PaginationMixin

A mixin that provides pagination logic without framework dependencies.

#### `loadMoreData<TData>`

Offset-based pagination method.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `fetchData` | `Future<TData> Function(int offset, int limit)` | ✅ Yes | - | Fetch function receiving (offset, limit). Return data or throw error. |
| `mergeData` | `TData Function(TData current, TData newData)` | ✅ Yes | - | Function to merge current and new data |
| `getCurrentCount` | `int Function(TData)` | ✅ Yes | - | Get current item count from data |
| `getTotalCount` | `int Function(TData)` | ✅ Yes | - | Get total available items count |
| `updateState` | `void Function(bool isLoading, TData? data, String? error)` | ✅ Yes | - | Update state with (isLoading, data, error) |
| `currentData` | `TData` | ✅ Yes | - | Current data from your state |
| `isCurrentlyLoading` | `bool` | ✅ Yes | - | Whether currently loading |
| `limit` | `int` | ❌ No | `10` | Items per page |
| `onError` | `void Function(dynamic)?` | ❌ No | `null` | Optional error callback |

#### `loadMoreWithPage<TData>`

Page-based pagination method (page starts from 1).

**Same parameters as `loadMoreData`**, but `fetchData` receives `(page, limit)` where:

- `page`: Starts from 1, increments: 1, 2, 3, 4...
- `limit`: Items per page

#### `loadMoreWithCursor<TData>`

Cursor-based pagination method.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `fetchData` | `Future<TData> Function(String? cursor, int limit)` | ✅ Yes | - | Fetch with cursor. Receives `null` for first page. |
| `mergeData` | `TData Function(TData current, TData newData)` | ✅ Yes | - | Function to merge current and new data |
| `getNextCursor` | `String? Function(TData)` | ✅ Yes | - | Extract next cursor from response. Return `null` if no more data. |
| `hasMoreData` | `bool Function(TData)` | ✅ Yes | - | Check if more data is available |
| `updateState` | `void Function(bool isLoading, TData? data, String? error)` | ✅ Yes | - | Update state callback |
| `currentData` | `TData` | ✅ Yes | - | Current data from your state |
| `isCurrentlyLoading` | `bool` | ✅ Yes | - | Whether currently loading |
| `limit` | `int` | ❌ No | `10` | Items per page |
| `onError` | `void Function(dynamic)?` | ❌ No | `null` | Optional error callback |

## ⚠️ Requirements

- Flutter: `>=3.0.0`
- Dart: `>=3.0.0 <4.0.0`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👤 Author

### Munawer

- GitHub: [@munawerdev](https://github.com/munawerdev)
- Repository: [pagination_helper](https://github.com/munawerdev/pagination_helper)

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed release notes.

---

Made with ❤️ for the Flutter community
