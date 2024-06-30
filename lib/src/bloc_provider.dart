import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
// import 'package:jaspr_bloc/src/test/test1.dart';
import 'package:jaspr_provider/jaspr_provider.dart';

/// Mixin which allows `MultiBlocProvider` to infer the types
/// of multiple [BlocProvider]s.
mixin BlocProviderSingleChildComponent on SingleChildComponent {}

/// {@template bloc_provider}
/// Takes a [Create] function that is responsible for
/// creating the [Bloc] or [Cubit] and a [child] which will have access
/// to the instance via `BlocProvider.of(context)`.
/// It is used as a dependency injection (DI) component so that a single
/// instance of a [Bloc] or [Cubit] can be provided to multiple components
/// within a subtree.
///
/// ```dart
/// BlocProvider(
///   create: (BuildContext context) => BlocA(),
///   child: ChildA(),
/// );
/// ```
///
/// It automatically handles closing the instance when used with [Create].
/// By default, [Create] is called only when the instance is accessed.
/// To override this behavior, set [lazy] to `false`.
///
/// ```dart
/// BlocProvider(
///   lazy: false,
///   create: (BuildContext context) => BlocA(),
///   child: ChildA(),
/// );
/// ```
///
/// {@endtemplate}
class BlocProvider<T extends StateStreamableSource<Object?>> extends SingleChildStatelessComponent with BlocProviderSingleChildComponent {
  /// {@macro bloc_provider}
  const BlocProvider({
    Key? key,
    required Create<T> create,
    this.child,
    this.lazy = true,
  })  : _create = create,
        _value = null,
        super(key: key, child: child);

  /// Takes a [value] and a [child] which will have access to the [value] via
  /// `BlocProvider.of(context)`.
  /// When `BlocProvider.value` is used, the [Bloc] or [Cubit]
  /// will not be automatically closed.
  /// As a result, `BlocProvider.value` should only be used for providing
  /// existing instances to new subtrees.
  ///
  /// A new [Bloc] or [Cubit] should not be created in `BlocProvider.value`.
  /// New instances should always be created using the
  /// default constructor within the [Create] function.
  ///
  /// ```dart
  /// BlocProvider.value(
  ///   value: BlocProvider.of<BlocA>(context),
  ///   child: ScreenA(),
  /// );
  /// ```
  const BlocProvider.value({
    Key? key,
    required T value,
    this.child,
  })  : _value = value,
        _create = null,
        lazy = true,
        super(key: key, child: child);

  /// Component which will have access to the [Bloc] or [Cubit].
  final Component? child;

  /// Whether the [Bloc] or [Cubit] should be created lazily.
  /// Defaults to `true`.
  final bool lazy;

  final Create<T>? _create;

  final T? _value;

  /// Method that allows components to access a [Bloc] or [Cubit] instance
  /// as long as their `BuildContext` contains a [BlocProvider] instance.
  ///
  /// If we want to access an instance of `BlocA` which was provided higher up
  /// in the component tree we can do so via:
  ///
  /// ```dart
  /// BlocProvider.of<BlocA>(context);
  /// ```
  static T of<T extends StateStreamableSource<Object?>>(
    BuildContext context, {
    bool listen = false,
  }) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException catch (e) {
      if (e.valueType != T) rethrow;
      throw Exception(
        '''
        BlocProvider.of() called with a context that does not contain a $T.
        No ancestor could be found starting from the context that was passed to BlocProvider.of<$T>().
        This can happen if the context you used comes from a component above the BlocProvider.
        The context used was: $context
        ''',
      );
    }
  }

  // @override
  // Iterable<Component> buildWithChild(BuildContext context, Component? child) {
  //   throw UnimplementedError();
  // }

  @override
  Iterable<Component> buildWithChild(
    BuildContext context,
    Component? child,
  ) sync* {
    assert(
      child != null,
      '$runtimeType used outside of MultiBlocProvider must specify a child',
    );
    final value = _value;
    yield value != null
        ? InheritedProvider<T>.value(
            value: value,
            startListening: _startListening,
            lazy: lazy,
            child: child,
          )
        : InheritedProvider<T>(
            create: _create,
            dispose: (_, bloc) => bloc.close(),
            startListening: _startListening,
            child: child,
            lazy: lazy,
          );
  }

  static VoidCallback _startListening(
    BuildContext e, // InheritedContext<StateStreamable?> e,
    StateStreamable value,
  ) {
    return () {};
    // final subscription = value.stream.listen(
    //   (dynamic _) => e.markNeedsNotifyDependents(),
    // );
    // return subscription.cancel;
  }
}
