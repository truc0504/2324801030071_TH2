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

  // Lịch sử tính toán
  final List<String> _history = [];

  // Bộ nhớ của máy tính
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

  // =========================
  // NHẬP SỐ
  // =========================

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

  // =========================
  // PHÉP TÍNH CƠ BẢN
  // =========================

  void _calculate() {
    if (_isError() ||
        _display == "-" ||
        _display.endsWith(",") ||
        _endsWithOperator()) {
      return;
    }

    String oldExpression = _display;
    num? result = _evaluateExpression(_display);

    if (result == null) {
      setState(() {
        _display = "Lỗi phép tính";
        _isEquationFinished = true;
      });
      return;
    }

    String formattedResult = _formatNumber(result);

    setState(() {
      _display = formattedResult;
      _isEquationFinished = true;

      _addHistory("$oldExpression = $formattedResult");
    });
  }

  num? _evaluateExpression(String expression) {
    try {
      String convertedExpression = expression
          .replaceAll("×", "*")
          .replaceAll("÷", "/")
          .replaceAll(",", ".");

      ExpressionParser parser = GrammarParser();
      Expression exp = parser.parse(convertedExpression);

      ContextModel contextModel = ContextModel();
      RealEvaluator evaluator = RealEvaluator(contextModel);

      num result = evaluator.evaluate(exp);

      if (result.isInfinite || result.isNaN) {
        return null;
      }

      return result;
    } catch (e) {
      return null;
    }
  }

  // =========================
  // CHỨC NĂNG NÂNG CAO
  // =========================

  void _square() {
    num? value = _evaluateCurrentValue();

    if (value == null) {
      return;
    }

    String oldValue = _display;
    num result = value * value;
    String formattedResult = _formatNumber(result);

    setState(() {
      _display = formattedResult;
      _isEquationFinished = true;

      _addHistory("$oldValue² = $formattedResult");
    });
  }

  void _squareRoot() {
    num? value = _evaluateCurrentValue();

    if (value == null) {
      return;
    }

    if (value < 0) {
      setState(() {
        _display = "Không thể căn số âm";
        _isEquationFinished = true;
      });
      return;
    }

    String oldValue = _display;
    num result = math.sqrt(value);
    String formattedResult = _formatNumber(result);

    setState(() {
      _display = formattedResult;
      _isEquationFinished = true;

      _addHistory("√($oldValue) = $formattedResult");
    });
  }

  void _reciprocal() {
    num? value = _evaluateCurrentValue();

    if (value == null) {
      return;
    }

    if (value == 0) {
      setState(() {
        _display = "Không thể chia cho 0";
        _isEquationFinished = true;
      });
      return;
    }

    String oldValue = _display;
    num result = 1 / value;
    String formattedResult = _formatNumber(result);

    setState(() {
      _display = formattedResult;
      _isEquationFinished = true;

      _addHistory("1/($oldValue) = $formattedResult");
    });
  }

  void _percent() {
    num? value = _evaluateCurrentValue();

    if (value == null) {
      return;
    }

    String oldValue = _display;
    num result = value / 100;
    String formattedResult = _formatNumber(result);

    setState(() {
      _display = formattedResult;
      _isEquationFinished = true;

      _addHistory("$oldValue% = $formattedResult");
    });
  }

  void _toggleSign() {
    if (_isError()) {
      return;
    }

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
        if (_display == "0") {
          return;
        }

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

  // =========================
  // CE VÀ BACKSPACE
  // =========================

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
        _display = _display.substring(0, operatorIndex + 1);
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
        _display = _display.substring(0, _display.length - 1);

        if (_display == "-") {
          _display = "0";
        }
      } else {
        _display = "0";
      }
    });
  }

  // =========================
  // BỘ NHỚ
  // =========================

  void _memoryStore() {
    num? value = _evaluateCurrentValue();

    if (value == null) {
      return;
    }

    setState(() {
      _memory = value;
    });

    _showMessage("Đã lưu MS = ${_formatNumber(_memory)}");
  }

  void _memoryAdd() {
    num? value = _evaluateCurrentValue();

    if (value == null) {
      return;
    }

    setState(() {
      _memory += value;
    });

    _showMessage("M = ${_formatNumber(_memory)}");
  }

  void _memorySubtract() {
    num? value = _evaluateCurrentValue();

    if (value == null) {
      return;
    }

    setState(() {
      _memory -= value;
    });

    _showMessage("M = ${_formatNumber(_memory)}");
  }

  // =========================
  // LỊCH SỬ
  // =========================

  void _addHistory(String calculation) {
    _history.insert(0, calculation);

    // Không để lịch sử quá dài
    if (_history.length > 50) {
      _history.removeLast();
    }
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF242424),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        16,
                        12,
                        8,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Lịch sử tính toán",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_history.isNotEmpty)
                            IconButton(
                              tooltip: "Xóa lịch sử",
                              onPressed: () {
                                setState(() {
                                  _history.clear();
                                });

                                setModalState(() {});
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _history.isEmpty
                          ? const Center(
                              child: Text(
                                "Chưa có phép tính nào",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _history.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                return Text(
                                  _history[index],
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================
  // HÀM HỖ TRỢ
  // =========================

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

    return _operators.contains(_display[_display.length - 1]);
  }

  bool _isError() {
    return _display == "Lỗi phép tính" ||
        _display == "Không thể chia cho 0" ||
        _display == "Không thể căn số âm";
  }

  int _findLastBinaryOperator() {
    for (int i = _display.length - 1; i >= 0; i--) {
      String character = _display[i];

      if (!_operators.contains(character)) {
        continue;
      }

      // Dấu trừ ở đầu là dấu âm, không phải phép trừ
      if (character == "-" && i == 0) {
        continue;
      }

      // Dấu trừ đứng sau một toán tử là dấu âm của số
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

    if ((number - number.round()).abs() < 0.00000001) {
      return number.round().toString();
    }

    String result = number.toStringAsFixed(8);

    result = result
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');

    return result.replaceAll(".", ",");
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  // =========================
  // GIAO DIỆN
  // =========================

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
            tooltip: "Lịch sử",
            onPressed: _showHistory,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Khu vực hiển thị
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
                    fontSize: _display.length > 15 ? 42 : 64,
                    fontWeight: FontWeight.w300,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Các nút bộ nhớ
            _buildMemoryRow(),

            // Hàng 1
            _buildRow(["%", "CE", "C", "⌫"]),

            // Hàng 2
            _buildRow(["1/x", "x²", "√x", "÷"]),

            // Hàng 3
            _buildRow(["7", "8", "9", "×"]),

            // Hàng 4
            _buildRow(["4", "5", "6", "-"]),

            // Hàng 5
            _buildRow(["1", "2", "3", "+"]),

            // Hàng 6
            _buildRow(["+/-", "0", ",", "="]),

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
          Expanded(child: _buildMemoryButton("M+")),
          Expanded(child: _buildMemoryButton("M-")),
          Expanded(child: _buildMemoryButton("MS")),
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
    } else if (["0", ",", "+/-"].contains(text)) {
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
            fontWeight:
                isSpecial ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}