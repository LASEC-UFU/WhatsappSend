import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/contact.dart';
import '../widgets/app_button.dart';

/// Diálogo para adicionar ou editar um contato.
class ContactDialog extends StatefulWidget {
  const ContactDialog({super.key, this.contact});

  /// Contato a editar — null para criar novo.
  final Contact? contact;

  /// Abre o diálogo e retorna o contato resultante (ou null se cancelado).
  static Future<Contact?> show(BuildContext context, {Contact? contact}) {
    return showDialog<Contact>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ContactDialog(contact: contact),
    );
  }

  @override
  State<ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<ContactDialog> {
  late final TextEditingController _nameCtr;
  late final TextEditingController _phoneCtr;
  late final TextEditingController _msgCtr;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtr = TextEditingController(text: widget.contact?.name ?? '');
    _phoneCtr = TextEditingController(text: widget.contact?.phone ?? '');
    _msgCtr = TextEditingController(
      text: widget.contact?.individualMessage ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _phoneCtr.dispose();
    _msgCtr.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final result = widget.contact != null
        ? widget.contact!.copyWith(
            name: _nameCtr.text.trim(),
            phone: _phoneCtr.text.trim(),
            individualMessage: _msgCtr.text.trim(),
          )
        : Contact(
            name: _nameCtr.text.trim(),
            phone: _phoneCtr.text.trim(),
            individualMessage: _msgCtr.text.trim(),
          );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contact != null;
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              decoration: const BoxDecoration(
                color: AppColors.waDarkGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Editar Contato' : 'Novo Contato',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Corpo
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Nome'),
                    TextFormField(
                      controller: _nameCtr,
                      decoration: const InputDecoration(
                        hintText: 'Nome do contato',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 14),
                    _label('Telefone *'),
                    TextFormField(
                      controller: _phoneCtr,
                      decoration: const InputDecoration(
                        hintText: '5534991110001 ou (34) 9 9111-0001',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Formato: DDI + DDD + número   Ex: 5534991110001',
                      style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
                    ),
                    const SizedBox(height: 14),
                    _label('Mensagem individual (opcional)'),
                    TextFormField(
                      controller: _msgCtr,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'Deixe vazio para usar a mensagem padrão.\nVariáveis: {nome}  {telefone}',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botões
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          label: 'Cancelar',
                          onPressed: () => Navigator.of(context).pop(),
                          color: AppColors.neutralBtn,
                          hoverColor: AppColors.neutralBtnHover,
                          pressedColor: AppColors.neutralBtnPressed,
                          height: 36,
                          minWidth: 100,
                          radius: 18,
                        ),
                        const SizedBox(width: 10),
                        AppButton(
                          label: 'Salvar',
                          onPressed: _save,
                          icon: Icons.check,
                          height: 36,
                          minWidth: 100,
                          radius: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: Color(0xFF333333),
      ),
    ),
  );
}
