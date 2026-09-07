/// Reactive lifecycle of any async screen data. Controllers expose a
/// `Rx<DataState<T>>`; views switch on it (via `DataStateBuilder`) to show a
/// shimmer skeleton, the real UI, an empty state, or an error with retry.
///
/// This is the single source of truth for "what is this screen doing right
/// now?" across every feature, so 150+ screens all handle loading / empty /
/// error identically instead of each re-inventing it.
sealed class DataState<T> {
  const DataState();

  /// Nothing requested yet.
  const factory DataState.initial() = DataInitial<T>;

  /// A fetch is in flight (first load — show the skeleton).
  const factory DataState.loading() = DataLoading<T>;

  /// Data arrived and is non-empty.
  const factory DataState.success(T data) = DataSuccess<T>;

  /// The request succeeded but there is nothing to show.
  const factory DataState.empty() = DataEmpty<T>;

  /// The request failed. [message] is user-facing.
  const factory DataState.failure(String message) = DataFailure<T>;

  /// Convenience: the data if this is a success, else null.
  T? get valueOrNull => this is DataSuccess<T> ? (this as DataSuccess<T>).data : null;

  bool get isLoading => this is DataLoading<T>;
  bool get isSuccess => this is DataSuccess<T>;
}

class DataInitial<T> extends DataState<T> {
  const DataInitial();
}

class DataLoading<T> extends DataState<T> {
  const DataLoading();
}

class DataSuccess<T> extends DataState<T> {
  const DataSuccess(this.data);
  final T data;
}

class DataEmpty<T> extends DataState<T> {
  const DataEmpty();
}

class DataFailure<T> extends DataState<T> {
  const DataFailure(this.message);
  final String message;
}
