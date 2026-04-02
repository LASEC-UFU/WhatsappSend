import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../providers/config_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/section_card.dart';

/// Tela de configurações do aplicativo.
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _timeoutCtr;
  late TextEditingController _intMinCtr;
  late TextEditingController _intMaxCtr;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<ConfigProvider>().config;
    _timeoutCtr = TextEditingController(text: '${cfg.pageTimeout}');
    _intMinCtr = TextEditingController(text: '${cfg.intervalMin}');
    _intMaxCtr = TextEditingController(text: '${cfg.intervalMax}');
  }

  @override
  void dispose() {
    _timeoutCtr.dispose();
    _intMinCtr.dispose();
    _intMaxCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: SectionCard(
        title: 'Configurações de Envio',
        subtitle:
            'Controla os timeouts e intervalos de segurança entre mensagens.',
        accentColor: AppColors.blue,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Field(
                label: 'Timeout da página (segundos)',
                hint:
                    'Tempo máximo aguardando o WhatsApp Web carregar cada chat.',
                controller: _timeoutCtr,
                min: 10,
                max: 300,
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Intervalo mínimo entre envios (s)',
                hint:
                    'Pausa mínima entre mensagens. Reduzir aumenta risco de bloqueio.',
                controller: _intMinCtr,
                min: 1,
                max: 300,
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Intervalo máximo entre envios (s)',
                hint: 'Pausa máxima entre mensagens.',
                controller: _intMaxCtr,
                min: 1,
                max: 600,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O WhatsApp Web é aberto dentro do app. Na primeira execução, '
                        'escaneie o QR code. A sessão é salva automaticamente para '
                        'próximas execuções.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'Salvar Configurações',
                  icon: Icons.save_outlined,
                  onPressed: _save,
                  height: 38,
                  minWidth: 180,
                  radius: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final timeout = int.tryParse(_timeoutCtr.text) ?? 40;
    final intMin = int.tryParse(_intMinCtr.text) ?? 6;
    final intMax = int.tryParse(_intMaxCtr.text) ?? 14;

    if (intMin > intMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intervalo mínimo não pode ser maior que o máximo.'),
        ),
      );
      return;
    }

    context.read<ConfigProvider>().update(
          context.read<ConfigProvider>().config.copyWith(
                pageTimeout: timeout,
                intervalMin: intMin,
                intervalMax: intMax,
              ),
        );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configurações salvas.')));
  }
}

// ── Campo numérico ────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.min,
    required this.max,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: '${(min + max) ~/ 2}'),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null) return 'Informe um número válido';
            if (n < min || n > max) return 'Valor entre $min e $max';
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
        ),
      ],
    );
  }
}
