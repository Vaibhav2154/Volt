import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../init_dependencies.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../bloc/email_config_bloc.dart';
import '../bloc/email_config_event.dart';
import '../bloc/email_config_state.dart';

class EmailConfigPage extends StatefulWidget {
  const EmailConfigPage({super.key});

  @override
  State<EmailConfigPage> createState() => _EmailConfigPageState();
}

class _EmailConfigPageState extends State<EmailConfigPage> {
  final _appPasswordController = TextEditingController();
  bool _consentGiven = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final authLocalDataSource = sl<AuthLocalDataSource>();
    final token = await authLocalDataSource.getToken();
    setState(() {
      _token = token;
    });
    if (_token != null) {
      context.read<EmailConfigBloc>().add(
            GetEmailParsingStatusEvent(token: _token!),
          );
    }
  }

  @override
  void dispose() {
    _appPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Email Configuration',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocConsumer<EmailConfigBloc, EmailConfigState>(
        listener: (context, state) {
          if (state is EmailAppPasswordSetupSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.response.message),
                backgroundColor: ColorPalette.success,
              ),
            );
            _appPasswordController.clear();
            setState(() {
              _consentGiven = false;
            });
            if (_token != null) {
              context.read<EmailConfigBloc>().add(
                    GetEmailParsingStatusEvent(token: _token!),
                  );
            }
          } else if (state is EmailParsingDisabledSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.response.message),
                backgroundColor: ColorPalette.warning,
              ),
            );
            if (_token != null) {
              context.read<EmailConfigBloc>().add(
                    GetEmailParsingStatusEvent(token: _token!),
                  );
            }
          } else if (state is EmailConfigError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EmailConfigLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EmailParsingStatusLoaded) {
            final status = state.status;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: status.emailParsingEnabled
                            ? [
                                ColorPalette.success.withOpacity(0.15),
                                ColorPalette.success.withOpacity(0.08),
                              ]
                            : [
                                ColorPalette.warning.withOpacity(0.15),
                                ColorPalette.warning.withOpacity(0.08),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: status.emailParsingEnabled
                            ? ColorPalette.success.withOpacity(0.3)
                            : ColorPalette.warning.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status.emailParsingEnabled
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              color: status.emailParsingEnabled
                                  ? ColorPalette.success
                                  : ColorPalette.warning,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status.emailParsingEnabled
                                    ? 'Email Parsing Enabled'
                                    : 'Email Parsing Disabled',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          status.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (status.emailAddress != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Email: ${status.emailAddress}',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Setup/Update App Password Section
                  Text(
                    status.emailParsingEnabled
                        ? 'Update App Password'
                        : 'Setup Email Parsing',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your Gmail app password (16 characters) to enable automatic transaction parsing from your email.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _appPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Gmail App Password',
                      hintText: 'Enter 16-character app password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    maxLength: 16,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _consentGiven,
                        onChanged: (value) {
                          setState(() {
                            _consentGiven = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'I consent to enable email parsing for automatic transaction processing',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _token != null &&
                              _appPasswordController.text.length == 16 &&
                              _consentGiven
                          ? () {
                              context.read<EmailConfigBloc>().add(
                                    status.emailParsingEnabled
                                        ? UpdateAppPasswordEvent(
                                            appPassword:
                                                _appPasswordController.text,
                                            consent: _consentGiven,
                                            token: _token!,
                                          )
                                        : SetupAppPasswordEvent(
                                            appPassword:
                                                _appPasswordController.text,
                                            consent: _consentGiven,
                                            token: _token!,
                                          ),
                                  );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        status.emailParsingEnabled
                            ? 'Update Password'
                            : 'Enable Email Parsing',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (status.emailParsingEnabled) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _token != null
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Disable Email Parsing'),
                                    content: const Text(
                                      'Are you sure you want to disable email parsing? Your app password will be removed.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          context.read<EmailConfigBloc>().add(
                                                DisableEmailParsingEvent(
                                                  confirm: true,
                                                  token: _token!,
                                                ),
                                              );
                                        },
                                        child: const Text(
                                          'Disable',
                                          style: TextStyle(color: ColorPalette.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Disable Email Parsing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          if (state is EmailConfigError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_token != null) {
                        context.read<EmailConfigBloc>().add(
                              GetEmailParsingStatusEvent(token: _token!),
                            );
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

