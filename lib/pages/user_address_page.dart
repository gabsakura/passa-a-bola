import 'package:flutter/material.dart';
import '../data/constants.dart';
import '../services/address_validation_service.dart';
import '../services/user_address_service.dart';

class UserAddressPage extends StatefulWidget {
  const UserAddressPage({super.key});

  @override
  State<UserAddressPage> createState() => _UserAddressPageState();
}

class _UserAddressPageState extends State<UserAddressPage> {
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();

  bool _isValidating = false;
  bool _isSaving = false;
  AddressValidationResult? _validationResult;
  UserAddressInfo? _currentAddressInfo;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAddress() async {
    try {
      final addressInfo = await UserAddressService.getUserAddressInfo();
      if (addressInfo != null) {
        setState(() {
          _currentAddressInfo = addressInfo;
          _addressController.text = addressInfo.originalAddress;
        });
      }
    } catch (e) {
      print('DEBUG: Erro ao carregar endereço atual: $e');
    }
  }

  Future<void> _validateAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isValidating = true;
      _validationResult = null;
      _showSuggestions = false;
    });

    try {
      final result = await AddressValidationService.validateAddress(address);
      setState(() {
        _validationResult = result;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _validationResult = AddressValidationResult(
          isValid: false,
          error: 'Erro na validação: $e',
        );
        _isValidating = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (_validationResult == null || !_validationResult!.isValid) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await UserAddressService.validateAndSaveUserAddress(
        _addressController.text.trim(),
      );

      if (result.isValid) {
        setState(() {
          _currentAddressInfo = UserAddressInfo(
            originalAddress: _addressController.text.trim(),
            validation: result,
          );
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Endereço salvo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _getSuggestions() async {
    final address = _addressController.text.trim();
    if (address.length < 3) return;

    try {
      final suggestions = await AddressValidationService.getAddressSuggestions(
        address,
      );
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = true;
      });
    } catch (e) {
      print('DEBUG: Erro ao obter sugestões: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Endereço'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
        actions: [
          if (_currentAddressInfo != null)
            IconButton(
              onPressed: _clearAddress,
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar Endereço',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentAddressCard(),
            const SizedBox(height: 24),
            _buildAddressInputCard(),
            const SizedBox(height: 24),
            if (_validationResult != null) _buildValidationResultCard(),
            const SizedBox(height: 24),
            if (_showSuggestions && _suggestions.isNotEmpty)
              _buildSuggestionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAddressCard() {
    if (_currentAddressInfo == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Nenhum endereço cadastrado',
                style: KTextStyle.titleText.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Cadastre seu endereço para encontrar campeonatos próximos',
                style: KTextStyle.bodyText.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Endereço Cadastrado',
                  style: KTextStyle.titleText.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentAddressInfo!.displayAddress,
              style: KTextStyle.bodyText.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.place, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _currentAddressInfo!.shortAddress,
                  style: KTextStyle.smallText.copyWith(color: Colors.grey[600]),
                ),
                const Spacer(),
                if (_currentAddressInfo!.isInSaoPaulo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'São Paulo',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.analytics, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Confiança: ${(_currentAddressInfo!.confidence * 100).toStringAsFixed(0)}%',
                  style: KTextStyle.smallText.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cadastrar/Atualizar Endereço',
              style: KTextStyle.titleText.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              focusNode: _addressFocusNode,
              decoration: InputDecoration(
                labelText: 'Digite seu endereço completo',
                hintText: 'Ex: Rua das Flores, 123 - Centro, São Paulo - SP',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _validateAddress,
                        icon: const Icon(Icons.search),
                        tooltip: 'Validar Endereço',
                      ),
              ),
              onChanged: (value) {
                if (value.length >= 3) {
                  _getSuggestions();
                } else {
                  setState(() {
                    _showSuggestions = false;
                  });
                }
              },
              onSubmitted: (value) => _validateAddress(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _validationResult?.isValid == true && !_isSaving
                    ? _saveAddress
                    : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Endereço'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationResultCard() {
    final result = _validationResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isValid ? Icons.check_circle : Icons.error,
                  color: result.isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  result.isValid ? 'Endereço Válido' : 'Endereço Inválido',
                  style: KTextStyle.titleText.copyWith(
                    color: result.isValid ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (result.isValid) ...[
              Text(
                'Endereço formatado:',
                style: KTextStyle.bodyText.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.formattedAddress ?? 'N/A',
                style: KTextStyle.bodyText,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.place, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    result.shortAddress,
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (result.isInSaoPaulo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'São Paulo',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.analytics, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Confiança: ${(result.confidence * 100).toStringAsFixed(0)}%',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Erro: ${result.error}',
                style: KTextStyle.bodyText.copyWith(color: Colors.red[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sugestões de Endereços',
              style: KTextStyle.titleText.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._suggestions.map(
              (suggestion) => ListTile(
                dense: true,
                leading: const Icon(Icons.place, size: 16),
                title: Text(suggestion, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  _addressController.text = suggestion;
                  setState(() {
                    _showSuggestions = false;
                  });
                  _validateAddress();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAddress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Endereço'),
        content: const Text(
          'Tem certeza que deseja remover seu endereço cadastrado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await UserAddressService.clearUserAddress();
      setState(() {
        _currentAddressInfo = null;
        _addressController.clear();
        _validationResult = null;
      });
    }
  }
}
