/// State-management-agnostic pagination helper
///
/// Works with ANY state management solution: Cubit, Bloc, Provider, Riverpod, GetX, etc.
///
/// Usage with Cubit/Bloc:
/// ```dart
/// class MyCubit extends Cubit<MyState> with PaginationMixin {
///   Future<void> loadMore() async {
///     await loadMoreData<MyDataModel>(
///       fetchData: (offset, limit) async {
///         return await api.getProducts(skip: offset, limit: limit);
///       },
///       mergeData: (current, newData) => current.copyWith(
///         items: [...current.items, ...newData.items]
///       ),
///       getCurrentCount: (data) => data.items.length,
///       getTotalCount: (data) => data.total,
///       updateState: (isLoading, data, error) {
///         emit(state.copyWith(
///           isLoadingMore: isLoading,
///           data: data,
///           error: error,
///         ));
///       },
///       currentData: state.data,
///       isCurrentlyLoading: state.isLoadingMore,
///     );
///   }
/// }
/// ```
///
/// Usage with Provider/ChangeNotifier:
/// ```dart
/// class ProductProvider with ChangeNotifier, PaginationMixin {
///   ProductData _data = ProductData.empty();
///   bool _isLoadingMore = false;
///
///   Future<void> loadMore() async {
///     await loadMoreData<ProductData>(
///       fetchData: (offset, limit) async {
///         return await api.getProducts(skip: offset, limit: limit);
///       },
///       mergeData: (current, newData) => current.copyWith(
///         items: [...current.items, ...newData.items]
///       ),
///       getCurrentCount: (data) => data.items.length,
///       getTotalCount: (data) => data.total,
///       updateState: (isLoading, data, error) {
///         _isLoadingMore = isLoading;
///         if (data != null) _data = data;
///         notifyListeners();
///       },
///       currentData: _data,
///       isCurrentlyLoading: _isLoadingMore,
///     );
///   }
/// }
/// ```
mixin PaginationMixin {
  /// Universal pagination method that works with any state management
  ///
  /// Parameters:
  /// - [fetchData]: Function to fetch paginated data from API (offset, limit) - returns data or throws error
  /// - [mergeData]: Function to merge current data with newly fetched data
  /// - [getCurrentCount]: Function to get current item count from data
  /// - [getTotalCount]: Function to get total available items from data
  /// - [updateState]: Callback to update your state (isLoadingMore, mergedData, error)
  /// - [currentData]: Current data from your state
  /// - [isCurrentlyLoading]: Whether currently loading from your state
  /// - [limit]: Number of items to fetch per page (default: 10)
  /// - [onError]: Optional error handler callback
  Future<void> loadMoreData<TData>({
    required Future<TData> Function(int offset, int limit) fetchData,
    required TData Function(TData current, TData newData) mergeData,
    required int Function(TData) getCurrentCount,
    required int Function(TData) getTotalCount,
    required void Function(bool isLoadingMore, TData? data, String? error)
        updateState,
    required TData currentData,
    required bool isCurrentlyLoading,
    int limit = 10,
    void Function(dynamic error)? onError,
  }) async {
    // Early return if loading or no more data
    if (isCurrentlyLoading ||
        getCurrentCount(currentData) >= getTotalCount(currentData)) {
      return;
    }

    // Set loading
    updateState(true, null, null);

    try {
      final newData = await fetchData(getCurrentCount(currentData), limit);
      final mergedData = mergeData(currentData, newData);
      updateState(false, mergedData, null);
    } catch (e) {
      updateState(false, null, e.toString());
      onError?.call(e);
    }
  }

  /// Page-based pagination (traditional page 1, 2, 3...)
  ///
  /// Use this when your API expects page numbers instead of offsets
  Future<void> loadMoreWithPage<TData>({
    required Future<TData> Function(int page, int limit) fetchData,
    required TData Function(TData current, TData newData) mergeData,
    required int Function(TData) getCurrentCount,
    required int Function(TData) getTotalCount,
    required void Function(bool isLoadingMore, TData? data, String? error)
        updateState,
    required TData currentData,
    required bool isCurrentlyLoading,
    int limit = 10,
    void Function(dynamic error)? onError,
  }) async {
    if (isCurrentlyLoading ||
        getCurrentCount(currentData) >= getTotalCount(currentData)) {
      return;
    }

    updateState(true, null, null);

    try {
      // Calculate current page (1-indexed)
      final currentPage = (getCurrentCount(currentData) / limit).ceil() + 1;
      final newData = await fetchData(currentPage, limit);
      final mergedData = mergeData(currentData, newData);
      updateState(false, mergedData, null);
    } catch (e) {
      updateState(false, null, e.toString());
      onError?.call(e);
    }
  }
}
