import 'package:flutter/material.dart';

import '../../services/group_api_client.dart';
import '../../models/create_group_request.dart';
import '../../models/group_summary.dart';
import '../../models/group_api_exception.dart';
import '../../state/auth_state.dart';
import '../../theme/campus_colors.dart';


class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key, this.groupApiClient});

  final GroupApiClient? groupApiClient;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = groupCategories.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final client = widget.groupApiClient ?? GroupApiClient();
      final group = await client.createGroup(
        CreateGroupRequest(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          adminId: AuthProvider.of(context).value.currentUser!.id,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(group);
      }
    } on GroupApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo conectar con la API.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: campusBackground,
      appBar: AppBar(
        backgroundColor: campusBackground,
        foregroundColor: campusInk,
        title: const Text(
          'Nuevo grupo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: campusSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: campusInk.withAlpha(24)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: campusAccent,
                      child: Icon(Icons.groups_2_outlined),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los grupos creados aqui son no oficiales y quedan sin sello de verificacion.',
                        style: TextStyle(
                          color: campusInk,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo',
                  hintText: 'Ej. Club de lectura UNAL',
                ),
                maxLength: 80,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripcion',
                  hintText: 'Cuenta que hace el colectivo',
                ),
                maxLength: 180,
                minLines: 4,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Categoria'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: groupCategories.map((category) {
                  final selected = _category == category;
                  return ChoiceChip(
                    label: Text(groupCategoryLabel(category)),
                    selected: selected,
                    selectedColor: campusInk,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : campusInk,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _category = category),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveGroup,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isSaving ? 'Creando...' : 'Crear grupo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: campusInk,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: campusInk,
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
    );
  }
}
