# Flutter Pagination Helper

A lightweight and **state-management-agnostic** Flutter package for implementing pagination with minimal boilerplate. Works with **ANY** state management solution: Cubit, Bloc, Provider, Riverpod, GetX, setState, and more!

## Features

- **Universal**: Works with ANY state management (Cubit, Bloc, Provider, Riverpod, GetX, setState)
- **PaginatedListView**: Automatic infinite scrolling list with pull-to-refresh
- **PaginatedGridView**: Grid layout with pagination support
- **PaginationMixin**: Powerful mixin with zero framework dependencies
- **Flexible**: Supports offset-based, page-based, and cursor-based pagination
- **Type-safe**: Fully generic implementation
- **Customizable**: Loading indicators, empty states, thresholds, and more

## Quick Start

### 1. Using PaginatedListView (Works with ANY state management)

```dart
import 'package:flutter_pagination_helper/flutter_pagination_helper.dart';

PaginatedListView<Product>(
  items: products,  // Your list from any state management
  isLoadingMore: isLoadingMore,  // Your loading flag
  onRefresh: () => refresh(),  // Your refresh function
  onLoadMore: () => loadMore(),  // Your load more function
  itemBuilder: (context, product, index) {
    return ListTile(
      title: Text(product.name),
      subtitle: Text(product.price),
    );
  },
  emptyWidget: const Center(
    child: Text('No products found'),
  ),
)
```

## State Management Examples

### 🎯 1. Flutter Bloc/Cubit

```dart
class ProductCubit extends Cubit<ProductState> with PaginationMixin {
  final ApiService apiService;
  
  ProductCubit({required this.apiService}) : super(ProductState.initial());

  Future<void> loadMore() async {
    await loadMoreData<ProductData>(
      fetchData: (offset, limit) async {
        // Just return the data directly - throw error if fails
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
          emit(state.copyWith(
            isLoadingMore: false,
            error: error,
          ));
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
    emit(state.copyWith(
      data: ProductData.empty(),
      isLoadingMore: false,
    ));
    await loadMore();
  }
}
```

### 🎯 2. Provider / ChangeNotifier

```dart
class ProductProvider with ChangeNotifier, PaginationMixin {
  final ApiService apiService;
  
  ProductProvider({required this.apiService});

  ProductData _data = ProductData.empty();
  bool _isLoadingMore = false;
  String? _error;

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

// Usage in Widget
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

### 🎯 3. Riverpod

```dart
class ProductNotifier extends StateNotifier<ProductState> with PaginationMixin {
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
}

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>(
  (ref) => ProductNotifier(ref.watch(apiServiceProvider))..loadMore(),
);

// Usage in Widget
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

### 🎯 4. GetX

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

// Usage in Widget
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

### 🎯 5. setState (StatefulWidget)

```dart
class ProductListPage extends StatefulWidget {
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> with PaginationMixin {
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

## Advanced Features

### Pagination Types

#### 1. Offset-Based Pagination (Default)
```dart
await loadMoreData<ProductData>(
  fetchData: (offset, limit) async {
    // offset = 0, 10, 20, 30...
    // Return data directly, throw on error
    return await api.getProducts(skip: offset, limit: limit);
  },
  mergeData: (current, newData) => current.copyWith(
    products: [...current.products, ...newData.products],
  ),
  getCurrentCount: (data) => data.products.length,
  getTotalCount: (data) => data.total,
  updateState: (isLoading, data, error) {
    // Handle state update
  },
  currentData: yourCurrentData,
  isCurrentlyLoading: yourLoadingFlag,
);
```

#### 2. Page-Based Pagination
```dart
await loadMoreWithPage<ProductData>(
  fetchData: (page, limit) async {
    // page = 1, 2, 3, 4...
    return await api.getProducts(page: page, limit: limit);
  },
  mergeData: (current, newData) => current.copyWith(
    products: [...current.products, ...newData.products],
  ),
  getCurrentCount: (data) => data.products.length,
  getTotalCount: (data) => data.total,
  updateState: (isLoading, data, error) {
    // Handle state update
  },
  currentData: yourCurrentData,
  isCurrentlyLoading: yourLoadingFlag,
);
```

### Error Handling

```dart
await loadMoreData<ProductData>(
  fetchData: (offset, limit) async {
    try {
      return await api.getProducts(skip: offset, limit: limit);
    } catch (e) {
      // API will throw, mixin catches it
      throw Exception('Failed to load products: $e');
    }
  },
  // ... other params
  updateState: (isLoading, data, error) {
    if (error != null) {
      // Handle error in your state
      showErrorSnackbar(error);
    }
  },
  onError: (error) {
    // Optional: Additional error handling
    print('Pagination error: $error');
  },
);
```

### Custom Loading Widget

```dart
PaginatedListView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  onLoadMore: () => cubit.loadMore(),
  itemBuilder: (context, product, index) => ProductCard(product),
  loadingWidget: const Padding(
    padding: EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(width: 16),
        Text('Loading more products...'),
      ],
    ),
  ),
)
```

### Grid View with Pagination

```dart
PaginatedGridView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: 0.7,
  onLoadMore: () => cubit.loadMore(),
  itemBuilder: (context, product, index) {
    return ProductGridCard(product: product);
  },
)
```

### Custom Load More Threshold

```dart
PaginatedListView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  loadMoreThreshold: 500.0, // Trigger 500px before bottom
  onLoadMore: () => cubit.loadMore(),
  itemBuilder: (context, product, index) => ProductCard(product),
)
```

### With Separators

```dart
PaginatedListView<Product>(
  items: products,
  isLoadingMore: isLoadingMore,
  onLoadMore: () => cubit.loadMore(),
  itemBuilder: (context, product, index) => ProductCard(product),
  separatorBuilder: (context, index) => const Divider(),
)
```

## API Reference

### PaginatedListView

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| items | List\<T\> | Yes | List of items to display |
| isLoadingMore | bool | Yes | Whether currently loading more items |
| itemBuilder | Widget Function | Yes | Builder for individual items |
| onLoadMore | VoidCallback | Yes | Called when more items needed |
| onRefresh | Future\<void\> Function()? | No | Pull-to-refresh callback |
| loadingWidget | Widget? | No | Custom loading indicator |
| emptyWidget | Widget? | No | Widget shown when list is empty |
| loadMoreThreshold | double | No | Distance from bottom to trigger load (default: 200) |
| separatorBuilder | Widget Function? | No | Builder for item separators |
| enableRefresh | bool | No | Enable pull-to-refresh (default: true) |

### PaginatedGridView

Includes all parameters from PaginatedListView plus:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| crossAxisCount | int | Yes | Number of columns |
| childAspectRatio | double | No | Width/height ratio (default: 1.0) |
| crossAxisSpacing | double | No | Horizontal spacing (default: 0) |
| mainAxisSpacing | double | No | Vertical spacing (default: 0) |

### PaginationMixin

#### loadMoreData\<TData\>

| Parameter | Type | Description |
|-----------|------|-------------|
| fetchData | Future\<TData\> Function(int, int) | Fetch function receiving (offset, limit). Return data or throw error. |
| mergeData | TData Function(TData, TData) | Function to merge current and new data |
| getCurrentCount | int Function(TData) | Get current item count |
| getTotalCount | int Function(TData) | Get total available items |
| updateState | void Function(bool, TData?, String?) | Update state with (isLoading, data, error) |
| currentData | TData | Current data from your state |
| isCurrentlyLoading | bool | Whether currently loading |
| limit | int | Items per page (default: 10) |
| onError | void Function(dynamic)? | Optional error callback |

#### loadMoreWithPage\<TData\>

Same as `loadMoreData` but `fetchData` receives `(page, limit)` where page starts from 1.

#### loadMoreWithCursor\<TData\>

| Parameter | Type | Description |
|-----------|------|-------------|
| fetchData | Future\<TData\> Function(String?, int) | Fetch with cursor |
| mergeData | TData Function(TData, TData) | Merge function |
| getNextCursor | String? Function(TData) | Extract next cursor |
| hasMoreData | bool Function(TData) | Check if more data available |
| updateState | void Function(bool, TData?, String?) | State update callback |
| currentData | TData | Current data |
| isCurrentlyLoading | bool | Loading state |
| limit | int | Items per page (default: 10) |
| onError | void Function(dynamic)? | Optional error callback |

## Requirements

- Flutter: >=3.0.0
- Dart: >=3.0.0 <4.0.0

## License

MIT License

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

1. Fork the repository (`https://github.com/munawerdev/mason_cli`)
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Author

Munawer

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release notes.