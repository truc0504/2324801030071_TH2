import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF171717),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = "0";
  bool _isEquationFinished = false;

  final List<String> _history = [];
  final List<String> _memoryHistory = [];

  num _memory = 0;

  final List<String> _operators = ["+", "-", "×", "÷"];

  void _onPressed(String text) {
    if (text == "C") {
      setState(() {
        _display = "0";
        _isEquationFinished = false;
      });
      return;
    }

    if (text == "CE") {
      _clearEntry();
      return;
    }

    if (text == "⌫") {
      _backspace();
      return;
    }

    if (text == "=") {
      _calculate();
      return;
    }

    if (text == "x²") {
      _square();
      return;
    }

    if (text == "√x") {
      _squareRoot();
      return;
    }

    if (text == "1/x") {
      _reciprocal();
      return;
    }

    if (text == "%") {
      _percent();
      return;
    }

    if (text == "+/-") {
      _toggleSign();
      return;
    }

    if (text == "MS") {
      _memoryStore();
      return;
    }

    if (text == "M+") {
      _memoryAdd();
      return;
    }

    if (text == "M-") {
      _memorySubtract();
      return;
    }

    if (_operators.contains(text)) {
      _addOperator(text);
      return;
    }

    if (text == ",") {
      _addDecimal();
      return;
    }

    _addNumber(text);
  }

  void _addNumber(String text) {
    setState(() {
      if (_isError()) {
        _display = "0";
      }

      if (_isEquationFinished) {
        _display = "0";
        _isEquationFinished = false;
      }

      if (_display == "0") {
        _display = text;
      } else {
        _display += text;
      }
    });
  }

  void _addDecimal() {
    setState(() {
      if (_isError()) {
        _display = "0";
      }

      if (_isEquationFinished) {
        _display = "0";
        _isEquationFinished = false;
      }

      int operatorIndex = _findLastBinaryOperator();

      String currentNumber;

      if (operatorIndex == -1) {
        currentNumber = _display;
      } else {
        currentNumber = _display.substring(operatorIndex + 1);
      }

      if (currentNumber.contains(",")) {
        return;
      }

      if (currentNumber.isEmpty || currentNumber == "-") {
        _display += "0,";
      } else {
        _display += ",";
      }
    });
  }

  void _addOperator(String text) {
    setState(() {
      if (_isError()) {
        _display = "0";
      }

      if (_display == "0" && text == "-") {
        _display = "-";
        _isEquationFinished = false;
        return;
      }

      if (_display == "-") {
        return;
      }

      if (_display.endsWith(",")) {
        _display = _display.substring(0, _display.length - 1);
      }

      if (_display.isEmpty) {
        _display = "0";
      }

      String lastCharacter = _display[_display.length - 1];

      if (_operators.contains(lastCharacter)) {
        _display =
            _display.substring(0, _display.length - 1) + text;
      } else {
        _display += text;
      }

      _isEquationFinished = false;
    });
  }

  void _calculate() {
    if (_isEquationFinished) {
      return;
    }

    if (_isError() ||
        _display == "-" ||
        _display.endsWith(",") ||
        _endsWithOperator()) {
      return;
    }

    String oldExpression = _display;

    if (_containsDivisionByZero(oldExpression)) {
      setState(() {
        _display = "Cannot divide by zero";
        _isEquationFinished = true;
      });
      return;
    }

    num? result = _evaluateExpression(_display);

    if (result == null) {
      setState(() {
        _display = "Invalid operation";
        _isEquationFinished = true;
      });
      return;
    }

    String formattedResult = _formatNumber(result);

    setState(() {
      _display = formattedResult;
      _isEquationFinished = true;

      _addHistory(
        "$oldExpression = $formattedResult",
      );
    });
  }

  num? _evaluateExpression(String expression) {
    try {
      String convertedExpression = expression
          .replaceAll("×", "*")
          .replaceAll("÷", "/")
          .replaceAll(",", ".");

      ExpressionParser parser = GrammarParser();

      Expression exp = parser.parse(
        convertedExpression,
      );

      ContextModel contextModel = ContextModel();

      RealEvaluator evaluator = RealEvaluator(
        contextModel,
      );

      num result = evaluator.evaluate(exp);

      if (result.isInfinite || result.isNaN) {
        return null;
      }

      return result;
    } catch (e) {
      return null;
    }
  }

  String? _getCurrentNumber() {
    if (_isError() ||
        _display == "-" ||
        _display.endsWith(",") ||
        _endsWithOperator()) {
      return null;
    }

    int operatorIndex = _findLastBinaryOperator();

    if (operatorIndex == -1) {
      return _display;
    }

    return _display.substring(operatorIndex + 1);
  }

  void _replaceCurrentNumber(String newValue) {
    int operatorIndex = _findLastBinaryOperator();

    if (operatorIndex == -1) {
      _display = newValue;
    } else {
      _display =
          _display.substring(0, operatorIndex + 1) +
          newValue;
    }
  }

  void _square() {
    String? currentText = _getCurrentNumber();

    if (currentText == null) return;

    num? value = num.tryParse(
      currentText.replaceAll(",", "."),
    );

    if (value == null) return;

    num result = value * value;

    String formattedResult = _formatNumber(result);

    int operatorIndex = _findLastBinaryOperator();

    bool isPartOfExpression = operatorIndex != -1;

    setState(() {
      _replaceCurrentNumber(formattedResult);

      _isEquationFinished = !isPartOfExpression;

      _addHistory(
        "($currentText)² = $formattedResult",
      );
    });
  }

  void _squareRoot() {
    String? currentText = _getCurrentNumber();

    if (currentText == null) return;

    num? value = num.tryParse(
      currentText.replaceAll(",", "."),
    );

    if (value == null) return;

    if (value < 0) {
      setState(() {
        _display = "Invalid input";
        _isEquationFinished = true;
      });
      return;
    }

    num result = math.sqrt(value);

    String formattedResult = _formatNumber(result);

    int operatorIndex = _findLastBinaryOperator();

    bool isPartOfExpression = operatorIndex != -1;

    setState(() {
      _replaceCurrentNumber(formattedResult);

      _isEquationFinished = !isPartOfExpression;

      _addHistory(
        "√($currentText) = $formattedResult",
      );
    });
  }

  void _reciprocal() {
    String? currentText = _getCurrentNumber();

    if (currentText == null) return;

    num? value = num.tryParse(
      currentText.replaceAll(",", "."),
    );

    if (value == null) return;

    if (value == 0) {
      setState(() {
        _display = "Cannot divide by zero";
        _isEquationFinished = true;
      });
      return;
    }

    num result = 1 / value;

    String formattedResult = _formatNumber(result);

    int operatorIndex = _findLastBinaryOperator();

    bool isPartOfExpression = operatorIndex != -1;

    setState(() {
      _replaceCurrentNumber(formattedResult);

      _isEquationFinished = !isPartOfExpression;

      _addHistory(
        "1/($currentText) = $formattedResult",
      );
    });
  }

  void _percent() {
    String? currentText = _getCurrentNumber();

    if (currentText == null) return;

    num? value = num.tryParse(
      currentText.replaceAll(",", "."),
    );

    if (value == null) return;

    num result = value / 100;

    String formattedResult = _formatNumber(result);

    int operatorIndex = _findLastBinaryOperator();

    bool isPartOfExpression = operatorIndex != -1;

    setState(() {
      _replaceCurrentNumber(formattedResult);

      _isEquationFinished = !isPartOfExpression;

      _addHistory(
        "$currentText% = $formattedResult",
      );
    });
  }

  void _toggleSign() {
    if (_isError()) return;

    setState(() {
      if (_isEquationFinished) {
        num? value = _evaluateExpression(_display);

        if (value != null) {
          _display = _formatNumber(-value);
        }

        return;
      }

      int operatorIndex = _findLastBinaryOperator();

      if (operatorIndex == -1) {
        if (_display == "0") return;

        if (_display.startsWith("-")) {
          _display = _display.substring(1);
        } else {
          _display = "-$_display";
        }
      } else {
        String before =
            _display.substring(0, operatorIndex + 1);

        String currentNumber =
            _display.substring(operatorIndex + 1);

        if (currentNumber.isEmpty) {
          return;
        }

        if (currentNumber.startsWith("-")) {
          currentNumber = currentNumber.substring(1);
        } else {
          currentNumber = "-$currentNumber";
        }

        _display = before + currentNumber;
      }
    });
  }

  void _clearEntry() {
    setState(() {
      if (_isError() || _isEquationFinished) {
        _display = "0";
        _isEquationFinished = false;
        return;
      }

      int operatorIndex = _findLastBinaryOperator();

      if (operatorIndex == -1) {
        _display = "0";
      } else {
        _display =
            _display.substring(0, operatorIndex + 1);
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_isError() || _isEquationFinished) {
        _display = "0";
        _isEquationFinished = false;
        return;
      }

      if (_display.length > 1) {
        _display =
            _display.substring(0, _display.length - 1);

        if (_display == "-") {
          _display = "0";
        }
      } else {
        _display = "0";
      }
    });
  }

  void _memoryStore() {
    num? value = _evaluateCurrentValue();

    if (value == null) return;

    String formattedValue = _formatNumber(value);

    setState(() {
      _memory = value;

      _addMemoryHistory(
        "MS: $formattedValue → M = ${_formatNumber(_memory)}",
      );
    });

    _showMessage(
      "Memory stored: ${_formatNumber(_memory)}",
    );
  }

  void _memoryAdd() {
    num? value = _evaluateCurrentValue();

    if (value == null) return;

    num oldMemory = _memory;

    String formattedValue = _formatNumber(value);

    setState(() {
      _memory += value;

      _addMemoryHistory(
        "M+: ${_formatNumber(oldMemory)} + "
        "$formattedValue = ${_formatNumber(_memory)}",
      );
    });

    _showMessage(
      "Memory: ${_formatNumber(_memory)}",
    );
  }

  void _memorySubtract() {
    num? value = _evaluateCurrentValue();

    if (value == null) return;

    num oldMemory = _memory;

    String formattedValue = _formatNumber(value);

    setState(() {
      _memory -= value;

      _addMemoryHistory(
        "M-: ${_formatNumber(oldMemory)} - "
        "$formattedValue = ${_formatNumber(_memory)}",
      );
    });

    _showMessage(
      "Memory: ${_formatNumber(_memory)}",
    );
  }

  void _addHistory(String calculation) {
    _history.insert(0, calculation);

    if (_history.length > 50) {
      _history.removeLast();
    }
  }

  void _addMemoryHistory(String memoryAction) {
    _memoryHistory.insert(0, memoryAction);

    if (_memoryHistory.length > 50) {
      _memoryHistory.removeLast();
    }
  }

  void _useSavedValue(String item) {
    int equalIndex = item.lastIndexOf("=");

    if (equalIndex == -1) return;

    String value = item.substring(equalIndex + 1).trim();

    setState(() {
      _display = value;
      _isEquationFinished = true;
    });

    Navigator.pop(context);
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF242424),
      isScrollControlled: true,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: SizedBox(
                  height:
                      MediaQuery.of(context).size.height *
                      0.60,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(
                            icon: Icon(Icons.history),
                            text: "History",
                          ),
                          Tab(
                            icon: Icon(Icons.memory),
                            text: "Memory",
                          ),
                        ],
                      ),

                      Expanded(
                        child: TabBarView(
                          children: [
                            Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(
                                    20,
                                    10,
                                    12,
                                    5,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          "History",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      if (_history.isNotEmpty)
                                        IconButton(
                                          tooltip:
                                              "Clear History",
                                          onPressed: () {
                                            setState(() {
                                              _history.clear();
                                            });

                                            setModalState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const Divider(height: 1),

                                Expanded(
                                  child: _history.isEmpty
                                      ? const Center(
                                          child: Text(
                                            "No history",
                                            style: TextStyle(
                                              color:
                                                  Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          itemCount:
                                              _history.length,
                                          separatorBuilder:
                                              (context, index) =>
                                                  const Divider(
                                            height: 1,
                                          ),
                                          itemBuilder:
                                              (context, index) {
                                            return ListTile(
                                              onTap: () {
                                                _useSavedValue(
                                                  _history[index],
                                                );
                                              },
                                              title: Text(
                                                _history[index],
                                                textAlign:
                                                    TextAlign.right,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 20,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),

                            Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(
                                    20,
                                    10,
                                    12,
                                    5,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Memory: ${_formatNumber(_memory)}",
                                          style:
                                              const TextStyle(
                                            fontSize: 18,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      if (_memory != 0 ||
                                          _memoryHistory
                                              .isNotEmpty)
                                        IconButton(
                                          tooltip:
                                              "Clear Memory",
                                          onPressed: () {
                                            setState(() {
                                              _memory = 0;
                                              _memoryHistory
                                                  .clear();
                                            });

                                            setModalState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const Divider(height: 1),

                                Expanded(
                                  child:
                                      _memoryHistory.isEmpty
                                      ? const Center(
                                          child: Text(
                                            "No memory history",
                                            style: TextStyle(
                                              color:
                                                  Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          itemCount:
                                              _memoryHistory
                                                  .length,
                                          separatorBuilder:
                                              (context, index) =>
                                                  const Divider(
                                            height: 1,
                                          ),
                                          itemBuilder:
                                              (context, index) {
                                            return ListTile(
                                              onTap: () {
                                                _useSavedValue(
                                                  _memoryHistory[
                                                      index],
                                                );
                                              },
                                              title: Text(
                                                _memoryHistory[
                                                    index],
                                                textAlign:
                                                    TextAlign.right,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 20,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  num? _evaluateCurrentValue() {
    if (_isError() ||
        _display == "-" ||
        _display.endsWith(",") ||
        _endsWithOperator()) {
      return null;
    }

    return _evaluateExpression(_display);
  }

  bool _endsWithOperator() {
    if (_display.isEmpty) {
      return false;
    }

    return _operators.contains(
      _display[_display.length - 1],
    );
  }

  bool _isError() {
    return _display == "Invalid operation" ||
        _display == "Cannot divide by zero" ||
        _display == "Invalid input";
  }

  bool _containsDivisionByZero(String expression) {
    String converted =
        expression.replaceAll(",", ".");

    RegExp divideByZero = RegExp(
      r'÷-?0+(?:\.0+)?(?=$|[+\-×÷])',
    );

    return divideByZero.hasMatch(converted);
  }

  int _findLastBinaryOperator() {
    for (int i = _display.length - 1; i >= 0; i--) {
      String character = _display[i];

      if (!_operators.contains(character)) {
        continue;
      }

      if (character == "-" && i == 0) {
        continue;
      }

      if (character == "-" &&
          i > 0 &&
          _operators.contains(_display[i - 1])) {
        continue;
      }

      return i;
    }

    return -1;
  }

  String _formatNumber(num value) {
    double number = value.toDouble();

    if ((number - number.round()).abs() <
        0.00000001) {
      return number.round().toString();
    }

    String result = number.toStringAsFixed(8);

    result = result
        .replaceFirst(
          RegExp(r'0+$'),
          '',
        )
        .replaceFirst(
          RegExp(r'\.$'),
          '',
        );

    return result.replaceAll(".", ",");
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(
            seconds: 1,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "2324801030071 - Nguyễn Hoàng Trúc",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "History",
            onPressed: _showHistory,
            icon: const Icon(
              Icons.history,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 25,
                ),
                child: Text(
                  _display,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize:
                        _display.length > 15 ? 42 : 64,
                    fontWeight: FontWeight.w300,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            _buildMemoryRow(),

            _buildRow([
              "%",
              "CE",
              "C",
              "⌫",
            ]),

            _buildRow([
              "1/x",
              "x²",
              "√x",
              "÷",
            ]),

            _buildRow([
              "7",
              "8",
              "9",
              "×",
            ]),

            _buildRow([
              "4",
              "5",
              "6",
              "-",
            ]),

            _buildRow([
              "1",
              "2",
              "3",
              "+",
            ]),

            _buildRow([
              "+/-",
              "0",
              ",",
              "=",
            ]),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryRow() {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: _buildMemoryButton("M+"),
          ),
          Expanded(
            child: _buildMemoryButton("M-"),
          ),
          Expanded(
            child: _buildMemoryButton("MS"),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryButton(String text) {
    return TextButton(
      onPressed: () => _onPressed(text),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRow(List<String> texts) {
    return Row(
      children: texts
          .map(
            (text) => Expanded(
              child: _buildButton(
                text,
                isSpecial: text == "=",
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildButton(
    String text, {
    bool isSpecial = false,
  }) {
    Color bgColor;
    Color textColor = Colors.white;

    if (text == "=") {
      bgColor = const Color(0xFF76C7FF);
      textColor = Colors.black;
    } else if ([
      "0",
      ",",
      "+/-",
    ].contains(text)) {
      bgColor = const Color(0xFF2D2D2D);
    } else if ([
      "÷",
      "×",
      "-",
      "+",
      "%",
      "CE",
      "C",
      "⌫",
      "1/x",
      "x²",
      "√x",
    ].contains(text)) {
      bgColor = const Color(0xFF323232);
    } else {
      bgColor = const Color(0xFF3B3B3B);
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.all(3),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
        ),
        onPressed: () => _onPressed(text),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isSpecial ? 25 : 19,
            fontWeight: isSpecial
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}