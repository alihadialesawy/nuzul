/// كلاس عام يمثل نتيجة أي عملية (بحث، حجز، تسجيل دخول...)
/// إما نجاح مع بيانات، أو فشل مع رسالة خطأ واضحة.
sealed class Result<T> {
  const Result();

  /// طريقة سريعة للتحقق والتعامل مع الحالتين معًا
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is Failure<T>) return failure(self.message);
    throw StateError('Unknown Result subtype');
  }

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}