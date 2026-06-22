import 'package:flutter/material.dart';
import '../data/constants.dart';
import '../widgets/formatted_text_field.dart';
import '../utils/text_formatters.dart';
import '../widgets/simple_address_field.dart';
import '../services/cep_service.dart';
import '../services/address_validation_service.dart';

class CadastroFormattedPage extends StatefulWidget {
  const CadastroFormattedPage({super.key});

  @override
  State<CadastroFormattedPage> createState() => _CadastroFormattedPageState();
}

class _CadastroFormattedPageState extends State<CadastroFormattedPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressController = TextEditingController();

  AddressValidationResult? _selectedLocation;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'Dados Pessoais',
                style: KTextStyle.largeTitleText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Nome
              FormattedTextField(
                controller: _nameController,
                labelText: 'Nome Completo',
                prefixIcon: Icons.person,
                keyboardType: TextInputType.text,
                fieldType: FormattedFieldType.normal,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              FormattedTextField(
                controller: _emailController,
                labelText: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                fieldType: FormattedFieldType.normal,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email é obrigatório';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Telefone
              FormattedTextField(
                controller: _phoneController,
                labelText: 'Telefone',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                fieldType: FormattedFieldType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telefone é obrigatório';
                  }
                  if (!TextFormatters.isValidPhone(value)) {
                    return 'Telefone inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CPF
              FormattedTextField(
                controller: _cpfController,
                labelText: 'CPF',
                prefixIcon: Icons.badge,
                keyboardType: TextInputType.number,
                fieldType: FormattedFieldType.cpf,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'CPF é obrigatório';
                  }
                  if (!TextFormatters.isValidCPF(value)) {
                    return 'CPF inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Data de Nascimento
              FormattedTextField(
                controller: _birthDateController,
                labelText: 'Data de Nascimento',
                prefixIcon: Icons.calendar_today,
                keyboardType: TextInputType.datetime,
                fieldType: FormattedFieldType.birthDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Data de nascimento é obrigatória';
                  }
                  if (!TextFormatters.isValidBirthDate(value)) {
                    return 'Data de nascimento inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Título para endereço
              Text(
                'Endereço',
                style: KTextStyle.largeTitleText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // CEP
              FormattedTextField(
                controller: _cepController,
                labelText: 'CEP',
                prefixIcon: Icons.location_on,
                keyboardType: TextInputType.number,
                fieldType: FormattedFieldType.cep,
                onChanged: (value) {
                  if (value.length == 9) {
                    // CEP completo
                    _searchAddressByCEP(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'CEP é obrigatório';
                  }
                  if (value.length != 9) {
                    return 'CEP deve ter 8 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Endereço com Google Maps
              SimpleAddressField(
                controller: _addressController,
                labelText: 'Endereço Completo',
                hintText: 'Digite o endereço completo...',
                onLocationChanged: (location) {
                  setState(() {
                    if (location != null) {
                      _selectedLocation = AddressValidationResult(
                        isValid: true,
                        latitude: location.latitude,
                        longitude: location.longitude,
                        formattedAddress: location.address,
                        city: location.city,
                        state: location.state,
                        country: location.country,
                      );
                    } else {
                      _selectedLocation = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // Informações da localização selecionada
              if (_selectedLocation != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Localização Confirmada',
                            style: KTextStyle.bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedLocation!.formattedAddress?.isNotEmpty == true
                            ? _selectedLocation!.formattedAddress!
                            : 'Coordenadas: ${_selectedLocation!.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${_selectedLocation!.longitude?.toStringAsFixed(6) ?? 'N/A'}',
                        style: KTextStyle.smallText.copyWith(
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botão de cadastrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KConstants.primaryColor,
                    foregroundColor: KConstants.textLightColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: KConstants.textLightColor,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Cadastrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchAddressByCEP(String cep) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final addressData = await CEPService.getAddressByCEP(cep);

      if (addressData != null && mounted) {
        setState(() {
          _addressController.text = addressData.formattedAddress;
          // Converter LocationData para AddressValidationResult
          _selectedLocation = AddressValidationResult(
            latitude: addressData.latitude,
            longitude: addressData.longitude,
            formattedAddress: addressData.formattedAddress,
            isInSaoPaulo: true,
            confidence: 1.0,
            isValid: true,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Endereço encontrado pelo CEP!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CEP não encontrado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar CEP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Aqui você integraria com o serviço de cadastro
      // para salvar os dados formatados

      // Debug: Dados do cadastro
      // print('DEBUG: Dados do cadastro:');
      // print('  Nome: ${_nameController.text.trim()}');
      // print('  Email: ${_emailController.text.trim()}');
      // print('  Telefone: ${_phoneController.text.trim()}');
      // print('  CPF: ${_cpfController.text.trim()}');
      // print('  Data de Nascimento: ${_birthDateController.text.trim()}');
      // print('  CEP: ${_cepController.text.trim()}');
      // print('  Endereço: ${_addressController.text.trim()}');
      // print('  Localização: ${_selectedLocation?.toJson()}');

      // Simula delay de cadastro
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
