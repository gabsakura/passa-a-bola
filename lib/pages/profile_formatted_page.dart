import 'package:flutter/material.dart';
import '../data/constants.dart';
import '../widgets/formatted_text_field.dart';
import '../utils/text_formatters.dart';
import '../widgets/simple_address_field.dart';
import '../services/address_validation_service.dart';

class ProfileFormattedPage extends StatefulWidget {
  const ProfileFormattedPage({super.key});

  @override
  State<ProfileFormattedPage> createState() => _ProfileFormattedPageState();
}

class _ProfileFormattedPageState extends State<ProfileFormattedPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _rgController = TextEditingController();
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
    _rgController.dispose();
    _birthDateController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil Completo'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Salvar',
              style: KTextStyle.buttonText.copyWith(
                color: KConstants.textLightColor,
              ),
            ),
          ),
        ],
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
                onChanged: (value) {
                  // Pode adicionar lógica adicional aqui
                },
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
                onChanged: (value) {
                  // Pode adicionar lógica adicional aqui
                },
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
                onChanged: (value) {
                  // Pode adicionar lógica adicional aqui
                },
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
                onChanged: (value) {
                  // Pode adicionar lógica adicional aqui
                },
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

              // RG
              FormattedTextField(
                controller: _rgController,
                labelText: 'RG',
                prefixIcon: Icons.credit_card,
                keyboardType: TextInputType.text,
                fieldType: FormattedFieldType.normal,
                onChanged: (value) {
                  // Pode adicionar lógica adicional aqui
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'RG é obrigatório';
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
                onChanged: (value) {
                  // Pode adicionar lógica adicional aqui
                },
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
                  // Pode buscar endereço pelo CEP aqui
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

              // Botão de salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
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
                      : const Text('Salvar Perfil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchAddressByCEP(String cep) async {
    // Remove formatação do CEP
    String cleanCEP = cep.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanCEP.length == 8) {
      try {
        // Aqui você pode integrar com uma API de CEP como ViaCEP
        // Por enquanto, apenas simula a busca
        // Debug: Buscando endereço para CEP: $cleanCEP

        // Exemplo de como seria a integração:
        // final address = await ViaCEPService.getAddress(cleanCEP);
        // if (address != null) {
        //   _addressController.text = address.formattedAddress;
        //   _selectedLocation = address.locationData;
        // }
      } catch (e) {
        // Debug: Erro ao buscar CEP: $e
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Aqui você integraria com o serviço de perfil
      // para salvar os dados formatados

      // Debug: Dados do perfil
      // print('DEBUG: Dados do perfil:');
      // print('  Nome: ${_nameController.text.trim()}');
      // print('  Email: ${_emailController.text.trim()}');
      // print('  Telefone: ${_phoneController.text.trim()}');
      // print('  CPF: ${_cpfController.text.trim()}');
      // print('  RG: ${_rgController.text.trim()}');
      // print('  Data de Nascimento: ${_birthDateController.text.trim()}');
      // print('  CEP: ${_cepController.text.trim()}');
      // print('  Endereço: ${_addressController.text.trim()}');
      // print('  Localização: ${_selectedLocation?.toJson()}');

      // Simula delay de salvamento
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar perfil: $e'),
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
