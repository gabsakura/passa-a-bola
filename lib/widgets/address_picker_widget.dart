import 'package:flutter/material.dart';
import '../data/constants.dart';
import '../services/address_validation_service.dart';

class AddressPickerWidget extends StatefulWidget {
  final String? initialAddress;
  final Function(AddressValidationResult?) onAddressSelected;
  final String? label;
  final String? hintText;

  const AddressPickerWidget({
    super.key,
    this.initialAddress,
    required this.onAddressSelected,
    this.label,
    this.hintText,
  });

  @override
  State<AddressPickerWidget> createState() => _AddressPickerWidgetState();
}

class _AddressPickerWidgetState extends State<AddressPickerWidget> {
  final TextEditingController _addressController = TextEditingController();
  AddressValidationResult? _validationResult;
  bool _isValidating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
      _validateAddress();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _validateAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() {
        _validationResult = null;
        _error = null;
      });
      widget.onAddressSelected(null);
      return;
    }

    setState(() {
      _isValidating = true;
      _error = null;
    });

    try {
      final result = await AddressValidationService.validateAddress(address);

      setState(() {
        _validationResult = result;
        _isValidating = false;
      });

      if (result.isValid) {
        widget.onAddressSelected(result);
      } else {
        setState(() {
          _error = result.error ?? 'Endereço inválido';
        });
        widget.onAddressSelected(null);
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
        _error = 'Erro ao validar endereço: $e';
      });
      widget.onAddressSelected(null);
    }
  }

  Future<void> _getAddressSuggestions() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    try {
      final suggestions = await AddressValidationService.getAddressSuggestions(
        address,
      );

      if (suggestions.isNotEmpty) {
        _showSuggestionsDialog(suggestions);
      }
    } catch (e) {
      print('Erro ao obter sugestões: $e');
    }
  }

  void _showSuggestionsDialog(List<String> suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sugestões de Endereço'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(suggestion),
                onTap: () {
                  _addressController.text = suggestion;
                  Navigator.of(context).pop();
                  _validateAddress();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: KTextStyle.titleText.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],

        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Ex: Avenida Paulista, 1000',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: _isValidating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _getAddressSuggestions,
                    tooltip: 'Buscar sugestões',
                  ),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            // Validar automaticamente após 1 segundo de pausa na digitação
            Future.delayed(const Duration(seconds: 1), () {
              if (_addressController.text == value) {
                _validateAddress();
              }
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Endereço é obrigatório';
            }
            if (_error != null) {
              return _error;
            }
            if (_validationResult != null && !_validationResult!.isValid) {
              return _validationResult!.error ?? 'Endereço inválido';
            }
            return null;
          },
        ),

        const SizedBox(height: 8),

        // Status da validação
        if (_validationResult != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _validationResult!.isValid
                  ? Colors.green[50]
                  : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _validationResult!.isValid
                    ? Colors.green[200]!
                    : Colors.red[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _validationResult!.isValid
                          ? Icons.check_circle
                          : Icons.error,
                      color: _validationResult!.isValid
                          ? Colors.green[600]
                          : Colors.red[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationResult!.isValid
                            ? 'Endereço válido'
                            : 'Endereço inválido',
                        style: TextStyle(
                          color: _validationResult!.isValid
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                if (_validationResult!.isValid) ...[
                  const SizedBox(height: 8),
                  Text(
                    _validationResult!.formattedAddress ??
                        _validationResult!.displayAddress,
                    style: KTextStyle.bodyText.copyWith(
                      color: Colors.green[700],
                    ),
                  ),

                  // Como todos os endereços são de São Paulo, mostrar sempre
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_city,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'São Paulo, SP',
                        style: KTextStyle.smallText.copyWith(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  if (_validationResult!.confidence < 0.8) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _validationResult!.confidence < 0.6
                                ? 'Validação aproximada - verifique o endereço'
                                : 'Confiança baixa na validação',
                            style: KTextStyle.smallText.copyWith(
                              color: Colors.orange[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else if (_validationResult!.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _validationResult!.error!,
                    style: KTextStyle.bodyText.copyWith(color: Colors.red[700]),
                  ),
                ],
              ],
            ),
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: KTextStyle.bodyText.copyWith(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
