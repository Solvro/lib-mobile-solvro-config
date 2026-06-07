import "package:analysis_server_plugin/plugin.dart";
import "package:analysis_server_plugin/registry.dart";
import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/token.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:analyzer/error/error.dart";
import "package:yaml/yaml.dart";

class SolvroCustomLinterPlugin extends Plugin {
  @override
  String get name => "solvro_custom_linter";

  @override
  void register(PluginRegistry registry) {
    <AnalysisRule>[
      AddHapticFeedbackOnUserInteractionRule(),
      AvoidHapticFeedbackInHapticOwningWidgetRule(),
      AvoidConsecutiveSliverToBoxAdapterRule(),
      AvoidHardcodedColorRule(),
      AvoidIconButtonWithoutTooltipRule(),
      AvoidIconWithoutSemanticLabelRule(),
      AvoidImageWithoutSemanticLabelRule(),
      AvoidSingleChildRule(),
      AssetImageRule(),
      CognitiveComplexityRule(),
      DisposeControllersRule(),
      FreezedMissingMixinRule(),
      HooksAvoidNestingRule(),
      HooksAvoidWithinClassRule(),
      HooksExtendsRule(),
      HooksNameConventionRule(),
      HooksUnuseWidgetRule(),
      PreferIterableAnyRule(),
      PreferIterableFirstRule(),
      PreferIterableLastRule(),
      PreferToIncludeSliverInNameRule(),
    ].forEach(registry.registerWarningRule);
  }
}

abstract class _SolvroRule extends AnalysisRule {
  _SolvroRule(this.code, String description)
    : super(name: code.lowerCaseName, description: description);

  final LintCode code;

  @override
  DiagnosticCode get diagnosticCode => code;
}

bool _isType(DartType? type, String name) => type?.getDisplayString() == name;

NamedExpression? _namedArgument(ArgumentList arguments, String name) {
  for (final argument in arguments.arguments) {
    if (argument is NamedExpression && argument.name.label.name == name) {
      return argument;
    }
  }
  return null;
}

bool _hasNamedArgument(ArgumentList arguments, String name) =>
    _namedArgument(arguments, name) != null;

class AvoidIconButtonWithoutTooltipRule extends _SolvroRule {
  AvoidIconButtonWithoutTooltipRule()
    : super(
        const LintCode(
          "avoid_icon_button_without_tooltip",
          "IconButton widgets should have a tooltip.",
        ),
        "Ensures IconButton widgets provide a tooltip.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(
      this,
      _InstanceVisitor(this, (node) {
        if (_isType(node.staticType, "IconButton") &&
            !_hasNamedArgument(node.argumentList, "tooltip")) {
          reportAtNode(node);
        }
      }),
    );
  }
}

class AvoidConsecutiveSliverToBoxAdapterRule extends _SolvroRule {
  AvoidConsecutiveSliverToBoxAdapterRule()
    : super(
        const LintCode(
          "avoid_consecutive_sliver_to_box_adapter",
          "Avoid using consecutive SliverToBoxAdapter widgets.",
        ),
        "Discourages consecutive SliverToBoxAdapter widgets in sliver lists.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addListLiteral(
      this,
      _ListLiteralVisitor(this, (node) {
        final iterator = node.elements.iterator;
        if (!iterator.moveNext()) {
          return;
        }

        var current = iterator.current;
        while (iterator.moveNext()) {
          final next = iterator.current;
          if (_usesSliverToBoxAdapter(current) &&
              _usesSliverToBoxAdapter(next)) {
            reportAtNode(node);
            return;
          }
          current = next;
        }
      }),
    );
  }

  bool _usesSliverToBoxAdapter(CollectionElement element) {
    if (element is! Expression) {
      return false;
    }
    if (element.staticType?.getDisplayString() == "SliverToBoxAdapter") {
      return true;
    }
    if (element is! InstanceCreationExpression) {
      return false;
    }
    for (final argument in element.argumentList.arguments) {
      if (argument is NamedExpression && argument.name.label.name == "sliver") {
        if (argument.expression.staticType?.getDisplayString() ==
            "SliverToBoxAdapter") {
          return true;
        }
      }
    }
    return false;
  }
}

class AvoidHardcodedColorRule extends _SolvroRule {
  AvoidHardcodedColorRule()
    : super(
        const LintCode(
          "avoid_hardcoded_color",
          "Avoid using hardcoded colors. Use ColorScheme-based definitions.",
        ),
        "Discourages hardcoded Color and Colors.* usages.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _HardcodedColorVisitor(this, context);
    registry
      ..addInstanceCreationExpression(this, visitor)
      ..addMethodInvocation(this, visitor)
      ..addPrefixedIdentifier(this, visitor);
  }
}

class AvoidSingleChildRule extends _SolvroRule {
  AvoidSingleChildRule()
    : super(
        const LintCode(
          "avoid_single_child",
          "Avoid using a single child in widgets that expect multiple children.",
        ),
        "Finds multi-child widgets used with a single child.",
      );

  static const _multiChildWidgets = {
    "Column",
    "Row",
    "Flex",
    "Wrap",
    "Stack",
    "ListView",
    "SliverList",
    "SliverMainAxisGroup",
    "SliverCrossAxisGroup",
  };

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(
      this,
      _InstanceVisitor(this, (node) {
        if (!_multiChildWidgets.contains(node.staticType?.getDisplayString())) {
          return;
        }

        final childrenArg =
            _namedArgument(node.argumentList, "children") ??
            _namedArgument(node.argumentList, "slivers");
        final expression = childrenArg?.expression;
        if (expression is! ListLiteral || expression.elements.length != 1) {
          return;
        }

        final element = expression.elements.single;
        if (element is ForElement) {
          return;
        }
        if (element is IfElement) {
          if (_hasMultipleChild(element.thenElement)) {
            return;
          }
          final elseElement = element.elseElement;
          if (elseElement != null && _hasMultipleChild(elseElement)) {
            return;
          }
        }
        reportAtNode(node);
      }),
    );
  }

  static bool _hasMultipleChild(CollectionElement element) {
    if (element is SpreadElement && element.expression is ListLiteral) {
      return (element.expression as ListLiteral).elements.length > 1;
    }
    return false;
  }
}

class AvoidIconWithoutSemanticLabelRule extends _SolvroRule {
  AvoidIconWithoutSemanticLabelRule()
    : super(
        const LintCode(
          "avoid_icon_without_semantic_label",
          "Icon widgets should have a semanticLabel.",
        ),
        "Ensures Icon widgets provide a semanticLabel.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(
      this,
      _InstanceVisitor(this, (node) {
        if (_isType(node.staticType, "Icon") &&
            !_hasNamedArgument(node.argumentList, "semanticLabel")) {
          reportAtNode(node);
        }
      }),
    );
  }
}

class AvoidImageWithoutSemanticLabelRule extends _SolvroRule {
  AvoidImageWithoutSemanticLabelRule()
    : super(
        const LintCode(
          "avoid_image_without_semantic_label",
          "Image widgets should have a semanticLabel.",
        ),
        "Ensures Image widgets provide a semanticLabel.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(
      this,
      _InstanceVisitor(this, (node) {
        if (_isType(node.staticType, "Image") &&
            !_hasNamedArgument(node.argumentList, "semanticLabel")) {
          reportAtNode(node);
        }
      }),
    );
  }
}

class AddHapticFeedbackOnUserInteractionRule extends _SolvroRule {
  AddHapticFeedbackOnUserInteractionRule()
    : super(
        const LintCode(
          "add_haptic_feedback_on_user_interaction",
          "User interactions should provide haptic feedback.",
        ),
        "Encourages HapticFeedback in interaction callbacks.",
      );

  static const _defaultHapticWrappers = ["HapticFeedback."];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final hapticWrappers = _configuredHapticWrappers(context);
    final hapticOwningWidgets = _configuredHapticOwningWidgets(context);

    registry.addNamedExpression(
      this,
      _NamedExpressionVisitor(this, (node) {
        if (!{
          "onTap",
          "onPressed",
          "onLongPress",
        }.contains(node.name.label.name)) {
          return;
        }

        if (_isCallbackInHapticOwningWidget(node, hapticOwningWidgets)) {
          return;
        }

        final source = node.expression.toString();
        if (!hapticWrappers.any(source.contains)) {
          reportAtNode(node);
        }
      }),
    );
  }

  static bool _isCallbackInHapticOwningWidget(
    NamedExpression node,
    List<String> hapticOwningWidgets,
  ) {
    final argumentList = node.parent;
    final creation = argumentList?.parent;
    if (argumentList is! ArgumentList ||
        creation is! InstanceCreationExpression) {
      return false;
    }

    final widgetName = creation.constructorName.type.name.lexeme;
    return hapticOwningWidgets.contains(widgetName);
  }

  static List<String> _configuredHapticWrappers(RuleContext context) {
    return _configuredStrings(
      context,
      singularName: "haptic_wrapper",
      pluralName: "haptic_wrappers",
      defaultValues: _defaultHapticWrappers,
    );
  }

  static List<String> _configuredHapticOwningWidgets(RuleContext context) {
    return _configuredStrings(
      context,
      singularName: "haptic_owning_widget",
      pluralName: "haptic_owning_widgets",
      defaultValues: const [],
    );
  }

  static List<String> _configuredStrings(
    RuleContext context, {
    required String singularName,
    required String pluralName,
    required List<String> defaultValues,
  }) {
    final package = context.package;
    if (package == null) {
      return defaultValues;
    }

    final optionsFile = package.root.getChildAssumingFile(
      "analysis_options.yaml",
    );
    if (!optionsFile.exists) {
      return defaultValues;
    }

    try {
      final options = loadYamlNode(optionsFile.readAsStringSync());
      if (options is! YamlMap) {
        return defaultValues;
      }

      final plugins = options["plugins"];
      if (plugins is! YamlMap) {
        return defaultValues;
      }

      for (final pluginName in ["solvro_config", "solvro_custom_linter"]) {
        final pluginConfig = plugins[pluginName];
        if (pluginConfig is! YamlMap) {
          continue;
        }

        final configuredStrings = <String>[];
        _addConfiguredStrings(configuredStrings, pluginConfig[singularName]);
        _addConfiguredStrings(configuredStrings, pluginConfig[pluralName]);

        if (configuredStrings.isNotEmpty) {
          return configuredStrings;
        }
      }
    } on YamlException {
      return defaultValues;
    } on Exception {
      return defaultValues;
    }

    return defaultValues;
  }

  static void _addConfiguredStrings(
    List<String> configuredStrings,
    Object? value,
  ) {
    if (value is String && value.isNotEmpty) {
      configuredStrings.add(value);
      return;
    }

    if (value is YamlList) {
      for (final item in value) {
        if (item is String && item.isNotEmpty) {
          configuredStrings.add(item);
        }
      }
    }
  }
}

class AvoidHapticFeedbackInHapticOwningWidgetRule extends _SolvroRule {
  AvoidHapticFeedbackInHapticOwningWidgetRule()
    : super(
        const LintCode(
          "avoid_haptic_feedback_in_haptic_owning_widget",
          "Haptic feedback is already provided by the widget and should not be duplicated.",
        ),
        "Prevents duplicate HapticFeedback in interaction callbacks for widgets that already provide it.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final hapticWrappers = {
      ...AddHapticFeedbackOnUserInteractionRule._configuredHapticWrappers(
        context,
      ),
      "HapticFeedback.",
    };
    final hapticOwningWidgets =
        AddHapticFeedbackOnUserInteractionRule._configuredHapticOwningWidgets(
          context,
        );

    registry.addNamedExpression(
      this,
      _NamedExpressionVisitor(this, (node) {
        if (!{
          "onTap",
          "onPressed",
          "onLongPress",
        }.contains(node.name.label.name)) {
          return;
        }

        if (!AddHapticFeedbackOnUserInteractionRule._isCallbackInHapticOwningWidget(
          node,
          hapticOwningWidgets,
        )) {
          return;
        }

        final source = node.expression.toString();
        if (hapticWrappers.any(source.contains)) {
          reportAtNode(node);
        }
      }),
    );
  }
}

class AssetImageRule extends _SolvroRule {
  AssetImageRule()
    : super(
        const LintCode(
          "asset_image",
          "AssetImage or Image.asset should not be used directly; use generated assets instead.",
        ),
        "Avoids direct AssetImage and Image.asset calls.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(
      this,
      _InstanceVisitor(this, (node) {
        if (node.constructorName.toString() == "AssetImage" ||
            node.constructorName.toString() == "Image.asset") {
          reportAtNode(node);
        }
      }),
    );
  }
}

class CognitiveComplexityRule extends _SolvroRule {
  CognitiveComplexityRule()
    : super(
        const LintCode(
          "cognitive_complexity",
          "Refactor this function to reduce its Cognitive Complexity.",
        ),
        "Reports functions with high cognitive complexity.",
      );

  static const threshold = 15;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _ComplexityVisitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class FreezedMissingMixinRule extends _SolvroRule {
  FreezedMissingMixinRule()
    : super(
        const LintCode(
          "freezed_missing_mixin",
          "Freezed classes should include the generated mixin.",
        ),
        "Ensures @freezed classes use their generated mixin.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(
      this,
      _ClassVisitor(this, (node) {
        if (!_hasFreezedAnnotation(node.metadata)) return;
        final expected = "_\$${node.namePart.typeName.lexeme}";
        final hasMixin =
            node.withClause?.mixinTypes.any(
              (type) => type.name.lexeme == expected,
            ) ??
            false;
        if (!hasMixin) reportAtToken(node.namePart.typeName);
      }),
    );
  }
}

bool _hasFreezedAnnotation(NodeList<Annotation> metadata) => metadata.any((a) {
  final name = a.name.name;
  return name == "freezed" || name == "Freezed";
});

class HooksAvoidNestingRule extends _SolvroRule {
  HooksAvoidNestingRule()
    : super(
        const LintCode(
          "hooks_avoid_nesting",
          "Hooks should not be called inside nested blocks.",
        ),
        "Prevents hook calls inside nested control flow.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(
      this,
      _MethodInvocationVisitor(this, (node) {
        if (_isHookCall(node) && _isNestedInControlFlow(node)) {
          reportAtNode(node);
        }
      }),
    );
  }
}

class HooksAvoidWithinClassRule extends _SolvroRule {
  HooksAvoidWithinClassRule()
    : super(
        const LintCode(
          "hooks_avoid_within_class",
          "Custom hooks should not be declared inside classes.",
        ),
        "Prevents declaring custom hooks inside classes.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodDeclaration(
      this,
      _MethodDeclarationVisitor(this, (node) {
        if (node.name.lexeme.startsWith("use")) reportAtToken(node.name);
      }),
    );
  }
}

class HooksNameConventionRule extends _SolvroRule {
  HooksNameConventionRule()
    : super(
        const LintCode(
          "hooks_name_convention",
          "Custom hooks should be prefixed with use.",
        ),
        "Enforces the custom hook naming convention.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addFunctionDeclaration(
      this,
      _FunctionDeclarationVisitor(this, (node) {
        final returnType = node.returnType?.toString() ?? "";
        if (returnType.contains("Hook") &&
            !node.name.lexeme.startsWith("use")) {
          reportAtToken(node.name);
        }
      }),
    );
  }
}

class HooksExtendsRule extends _SolvroRule {
  HooksExtendsRule()
    : super(
        const LintCode(
          "hooks_extends",
          "Widgets using hooks should extend HookWidget or HookConsumerWidget.",
        ),
        "Ensures widgets using hooks extend hook-aware widget classes.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(
      this,
      _ClassVisitor(this, (node) {
        final superclass = node.extendsClause?.superclass.name.lexeme;
        if (superclass == "HookWidget" || superclass == "HookConsumerWidget") {
          return;
        }
        final usesHook = node.toString().contains(RegExp(r"\buse[A-Z]\w*\("));
        if (usesHook) reportAtToken(node.namePart.typeName);
      }),
    );
  }
}

class HooksUnuseWidgetRule extends _SolvroRule {
  HooksUnuseWidgetRule()
    : super(
        const LintCode(
          "hooks_unuse_widget",
          "HookWidget or HookConsumerWidget should use hooks.",
        ),
        "Finds hook-aware widgets that do not call hooks.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(
      this,
      _ClassVisitor(this, (node) {
        final superclass = node.extendsClause?.superclass.name.lexeme;
        if (superclass != "HookWidget" && superclass != "HookConsumerWidget") {
          return;
        }
        final usesHook = node.toString().contains(RegExp(r"\buse[A-Z]\w*\("));
        if (!usesHook) reportAtToken(node.namePart.typeName);
      }),
    );
  }
}

class DisposeControllersRule extends _SolvroRule {
  DisposeControllersRule()
    : super(
        const LintCode(
          "dispose_controllers",
          "Controllers should be disposed.",
        ),
        "Ensures State classes dispose controller fields.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(
      this,
      _ClassVisitor(this, (node) {
        if (!_extendsState(node)) return;
        final fields = <String>[];
        for (final member in node.body.members.whereType<FieldDeclaration>()) {
          final type = member.fields.type?.toString() ?? "";
          if (!type.endsWith("Controller")) continue;
          for (final variable in member.fields.variables) {
            fields.add(variable.name.lexeme);
          }
        }
        if (fields.isEmpty) return;
        final dispose = node.body.members.whereType<MethodDeclaration>().where(
          (m) => m.name.lexeme == "dispose",
        );
        final disposeBody = dispose.isEmpty
            ? ""
            : dispose.first.body.toString();
        for (final field in fields) {
          if (!disposeBody.contains("$field.dispose()")) {
            reportAtToken(node.namePart.typeName);
          }
        }
      }),
    );
  }
}

class PreferIterableAnyRule extends _PreferIterableRule {
  PreferIterableAnyRule()
    : super(
        "prefer_iterable_any",
        "Prefer iterable.any(...) over where(...).isNotEmpty.",
        "any",
      );
}

class PreferIterableFirstRule extends _PreferIterableRule {
  PreferIterableFirstRule()
    : super(
        "prefer_iterable_first",
        "Prefer firstWhere(...) over where(...).first.",
        "first",
      );
}

class PreferIterableLastRule extends _PreferIterableRule {
  PreferIterableLastRule()
    : super(
        "prefer_iterable_last",
        "Prefer lastWhere(...) over where(...).last.",
        "last",
      );
}

class _PreferIterableRule extends _SolvroRule {
  _PreferIterableRule(String name, String message, this.kind)
    : super(LintCode(name, message), message);

  final String kind;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addPropertyAccess(
      this,
      _PropertyAccessVisitor(this, (node) {
        final target = node.target;
        if (target is! MethodInvocation || target.methodName.name != "where") {
          return;
        }
        final property = node.propertyName.name;
        if (kind == "any" && property == "isNotEmpty") reportAtNode(node);
        if (kind == "first" && property == "first") reportAtNode(node);
        if (kind == "last" && property == "last") reportAtNode(node);
      }),
    );
  }
}

class PreferToIncludeSliverInNameRule extends _SolvroRule {
  PreferToIncludeSliverInNameRule()
    : super(
        const LintCode(
          "prefer_to_include_sliver_in_name",
          "Widgets returning Sliver should include Sliver in the class name or named constructor.",
        ),
        "Ensures widgets returning slivers include Sliver in their name.",
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(
      this,
      _ClassVisitor(this, (node) {
        final buildMethod = node.body.members
            .whereType<MethodDeclaration>()
            .where((method) => method.name.lexeme == "build");
        if (buildMethod.isEmpty) {
          return;
        }

        final body = buildMethod.first.body;
        if (body is! BlockFunctionBody) {
          return;
        }

        final returnsSliver = body.block.statements
            .whereType<ReturnStatement>()
            .any((statement) {
              final typeName = statement.expression?.staticType
                  ?.getDisplayString();
              return typeName?.startsWith("Sliver") ?? false;
            });
        if (!returnsSliver ||
            node.namePart.typeName.lexeme.contains("Sliver")) {
          return;
        }

        final hasSliverConstructor = node.body.members
            .whereType<ConstructorDeclaration>()
            .map((constructor) => constructor.name?.lexeme)
            .nonNulls
            .any((name) => name.toLowerCase().contains("sliver"));
        if (!hasSliverConstructor) {
          reportAtToken(node.namePart.typeName);
        }
      }),
    );
  }
}

class _InstanceVisitor extends SimpleAstVisitor<void> {
  _InstanceVisitor(this.rule, this.check);

  final AnalysisRule rule;
  final void Function(InstanceCreationExpression node) check;
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) =>
      check(node);
}

class _NamedExpressionVisitor extends SimpleAstVisitor<void> {
  _NamedExpressionVisitor(this.rule, this.check);

  final AnalysisRule rule;
  final void Function(NamedExpression node) check;
  @override
  void visitNamedExpression(NamedExpression node) => check(node);
}

class _ListLiteralVisitor extends SimpleAstVisitor<void> {
  _ListLiteralVisitor(this.rule, this.check);

  final AnalysisRule rule;
  final void Function(ListLiteral node) check;
  @override
  void visitListLiteral(ListLiteral node) => check(node);
}

class _MethodInvocationVisitor extends SimpleAstVisitor<void> {
  _MethodInvocationVisitor(this.rule, this.check);

  final AnalysisRule rule;
  final void Function(MethodInvocation node) check;
  @override
  void visitMethodInvocation(MethodInvocation node) => check(node);
}

class _FunctionDeclarationVisitor extends SimpleAstVisitor<void> {
  _FunctionDeclarationVisitor(this.rule, this.check);

  final AnalysisRule rule;
  final void Function(FunctionDeclaration node) check;
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) => check(node);
}

class _MethodDeclarationVisitor extends SimpleAstVisitor<void> {
  _MethodDeclarationVisitor(this.rule, this.check);

  final AnalysisRule rule;
  final void Function(MethodDeclaration node) check;
  @override
  void visitMethodDeclaration(MethodDeclaration node) => check(node);
}

class _ClassVisitor extends SimpleAstVisitor<void> {
  _ClassVisitor(this.rule, this.check);

  final AnalysisRule rule;
  final void Function(ClassDeclaration node) check;
  @override
  void visitClassDeclaration(ClassDeclaration node) => check(node);
}

class _PropertyAccessVisitor extends SimpleAstVisitor<void> {
  _PropertyAccessVisitor(this.rule, this.check);

  final AnalysisRule rule;
  final void Function(PropertyAccess node) check;
  @override
  void visitPropertyAccess(PropertyAccess node) => check(node);
}

class _HardcodedColorVisitor extends SimpleAstVisitor<void> {
  _HardcodedColorVisitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  bool get _isTestFile {
    final path = context.definingUnit.file.path;
    return path.contains("/test/") || path.endsWith("_test.dart");
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_isTestFile || _isInsideColorScheme(node)) {
      return;
    }
    if (_isColorClass(node.staticType?.element)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isTestFile || _isInsideColorScheme(node)) {
      return;
    }

    final element = node.methodName.element;
    if (element is ConstructorElement &&
        _isColorClass(element.enclosingElement)) {
      rule.reportAtNode(node);
      return;
    }
    if (element is MethodElement &&
        element.isStatic &&
        _isColorClass(element.enclosingElement)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isTestFile || _isInsideColorScheme(node)) {
      return;
    }

    final element = node.element;
    if (element is! PropertyAccessorElement && element is! FieldElement) {
      return;
    }
    final parentClass = element?.enclosingElement;
    if (parentClass is! ClassElement || parentClass.name != "Colors") {
      return;
    }
    if (node.identifier.name == "transparent") {
      return;
    }

    final type = element is PropertyAccessorElement
        ? element.returnType
        : (element! as FieldElement).type;
    if (_isColorType(type)) {
      rule.reportAtNode(node);
    }
  }

  bool _isColorClass(Element? element) {
    if (element is! ClassElement) {
      return false;
    }
    return element.name == "Color" ||
        element.name == "MaterialColor" ||
        element.name == "MaterialAccentColor";
  }

  bool _isColorType(DartType? type) {
    if (type == null || type.isDartCoreInt) {
      return false;
    }
    return _isColorClass(type.element);
  }

  bool _isInsideColorScheme(AstNode node) {
    for (
      AstNode? parent = node.parent;
      parent != null;
      parent = parent.parent
    ) {
      if (parent is InstanceCreationExpression &&
          parent.staticType?.element?.name == "ColorScheme") {
        return true;
      }
      if (parent is MethodInvocation) {
        if (parent.target?.staticType?.element?.name == "ColorScheme") {
          return true;
        }
        if (parent.methodName.element?.enclosingElement?.name ==
            "ColorScheme") {
          return true;
        }
      }
    }
    return false;
  }
}

class _ComplexityVisitor extends SimpleAstVisitor<void> {
  _ComplexityVisitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final body = node.functionExpression.body;
    _check(node.name, body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _check(node.name, node.body);
  }

  void _check(Token token, FunctionBody body) {
    final counter = _ComplexityCounter();
    body.accept(counter);
    if (counter.score > CognitiveComplexityRule.threshold) {
      rule.reportAtToken(token);
    }
  }
}

class _ComplexityCounter extends RecursiveAstVisitor<void> {
  var score = 0;
  var nesting = 0;

  void _increment() => score += 1 + nesting;

  @override
  void visitIfStatement(IfStatement node) {
    _increment();
    nesting++;
    super.visitIfStatement(node);
    nesting--;
  }

  @override
  void visitForStatement(ForStatement node) {
    _increment();
    nesting++;
    super.visitForStatement(node);
    nesting--;
  }

  @override
  void visitForElement(ForElement node) {
    _increment();
    nesting++;
    super.visitForElement(node);
    nesting--;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _increment();
    nesting++;
    super.visitWhileStatement(node);
    nesting--;
  }

  @override
  void visitDoStatement(DoStatement node) {
    _increment();
    nesting++;
    super.visitDoStatement(node);
    nesting--;
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _increment();
    nesting++;
    super.visitSwitchStatement(node);
    nesting--;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _increment();
    super.visitConditionalExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.AMPERSAND_AMPERSAND ||
        node.operator.type == TokenType.BAR_BAR) {
      score++;
    }
    super.visitBinaryExpression(node);
  }
}

bool _isHookCall(MethodInvocation node) =>
    node.methodName.name.startsWith(RegExp("use[A-Z]"));

bool _isNestedInControlFlow(AstNode node) {
  for (
    AstNode? current = node.parent;
    current != null;
    current = current.parent
  ) {
    if (current is IfStatement ||
        current is ForStatement ||
        current is WhileStatement ||
        current is DoStatement ||
        current is SwitchStatement) {
      return true;
    }
    if (current is MethodDeclaration && current.name.lexeme == "build") {
      return false;
    }
    if (current is FunctionDeclaration) return false;
  }
  return false;
}

bool _extendsState(ClassDeclaration node) {
  final superclass = node.extendsClause?.superclass;
  if (superclass == null) return false;
  final name = superclass.name.lexeme;
  return name == "State" || name.endsWith("State");
}
