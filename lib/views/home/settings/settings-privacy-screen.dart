import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/keys/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/devices-settings/selectors.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/appbars/appbar-normal.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm-password.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  onExportDeviceKey({
    required _Props props,
    required BuildContext context,
  }) async {
    final store = StoreProvider.of<AppState>(context);
    await showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: 'Confirm Exporting Keys',
        content: Strings.contentKeyExportWarning,
        loading: props.loading,
        confirmText: 'Export Keys',
        confirmStyle: TextStyle(color: Theme.of(context).primaryColor),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          await store.dispatch(exportSessionKeys());
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  onDeleteDeviceKey({
    required _Props props,
    required BuildContext context,
  }) async {
    final store = StoreProvider.of<AppState>(context);
    await showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: Strings.titleConfirmDeleteKeys,
        content: Strings.confirmDeleteKeys,
        loading: props.loading,
        confirmText: 'Delete Keys',
        confirmStyle: TextStyle(color: Colors.red),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          await store.dispatch(deleteDeviceKeys());
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  onConfirmDeactivateAccount({
    required _Props props,
    required BuildContext context,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: 'Confirm Deactivate Account',
        content: Strings.warningDeactivateAccount,
        confirmText: Strings.buttonDeactivate.capitalize(),
        confirmStyle: TextStyle(color: Colors.red),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          props.onResetConfirmAuth();
          onConfirmDeactivateAccountFinal(props: props, context: context);
        },
      ),
    );
  }

  onConfirmDeactivateAccountFinal({
    required _Props props,
    required BuildContext context,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: 'Confirm Deactivate Account Final',
        content: Strings.warrningDeactivateAccountFinal,
        loading: props.loading,
        confirmText: Strings.buttonDeactivate.capitalize(),
        confirmStyle: TextStyle(color: Colors.red),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          await onDeactivateAccount(context: context);
        },
      ),
    );
  }

  onDeactivateAccount({required BuildContext context}) async {
    final store = StoreProvider.of<AppState>(context);

    // Attempt to deactivate account
    await store.dispatch(deactivateAccount());

    // Prompt for password if an Interactive Auth sessions was started
    final authSession = store.state.authStore.authSession;
    if (authSession != null) {
      showDialog(
        context: context,
        builder: (dialogContext) => DialogConfirmPassword(
          key: Key(authSession),
          title: Strings.titleConfirmPassword,
          content: Strings.confirmDeactivate,
          onConfirm: () async {
            await store.dispatch(deactivateAccount());
            Navigator.of(dialogContext).pop();
          },
          onCancel: () async {
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }
  }

  onExportSessionKeys({required BuildContext context}) async {
    final store = StoreProvider.of<AppState>(context);
    store.dispatch(exportSessionKeys());
  }

  onImportSessionKeys({required BuildContext context}) async {
    final store = StoreProvider.of<AppState>(context);
    store.dispatch(importSessionKeys());
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;

          return Scaffold(
            appBar: AppBarNormal(title: Strings.titlePrivacy),
            body: SingleChildScrollView(
                padding: Dimensions.scrollviewPadding,
                child: Column(
                  children: <Widget>[
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              Strings.titleVerification,
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Public Device Name',
                            ),
                            subtitle: Text(
                              props.sessionName,
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                          ListTile(
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Session ID',
                            ),
                            subtitle: Text(
                              props.sessionId,
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                          ListTile(
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Session Key',
                            ),
                            subtitle: Text(
                              props.sessionKey,
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              'User Access',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.settingsPassword);
                            },
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Change Password',
                            ),
                            subtitle: Text(
                              'Changing your password will refresh your\ncurrent session',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.settingsBlocked);
                            },
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Blocked Users',
                            ),
                            subtitle: Text(
                              'View and manage blocked users',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              'Communication',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            onTap: () => props.onIncrementReadReceipts(),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Read Receipts',
                            ),
                            subtitle: Text(
                              'If read receipts are disabled or hidden, users will not see solid read indicators for your messages.',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Text(props.readReceipts),
                          ),
                          ListTile(
                            onTap: () => props.onToggleTypingIndicators(),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Typing Indicators',
                            ),
                            subtitle: Text(
                              'If typing indicators are disabled, you won\'t be able to see typing indicators from others',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Switch(
                              value: props.typingIndicators!,
                              onChanged: (enterSend) => props.onToggleTypingIndicators(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              'App access',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            enabled: false,
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Screen lock',
                            ),
                            subtitle: Text(
                              'Lock ${Values.appName} access with native device screen lock or fingerprint',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Switch(
                              value: false,
                              onChanged: null,
                            ),
                          ),
                          ListTile(
                            enabled: false,
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Screen lock inactivity timeout',
                            ),
                            subtitle: Text(
                              'None',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              'Encryption Keys',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            enabled: false,
                            onTap: onImportSessionKeys(context: context),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Import Keys',
                            ),
                          ),
                          ListTile(
                            enabled: false,
                            onTap: () => onExportDeviceKey(context: context, props: props),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Export Keys',
                            ),
                          ),
                          ListTile(
                            onTap: () => onDeleteDeviceKey(context: context, props: props),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Delete Keys',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              'Account Management',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            onTap: () => onConfirmDeactivateAccount(
                              props: props,
                              context: context,
                            ),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Deactivate Account',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final bool? typingIndicators;

  final String sessionId;
  final String sessionName;
  final String sessionKey;
  final String readReceipts;

  final Function onToggleTypingIndicators;
  final Function onIncrementReadReceipts;
  final Function onDisabled;
  final Function onResetConfirmAuth;

  const _Props({
    required this.loading,
    required this.readReceipts,
    required this.typingIndicators,
    required this.sessionId,
    required this.sessionName,
    required this.sessionKey,
    required this.onDisabled,
    required this.onToggleTypingIndicators,
    required this.onIncrementReadReceipts,
    required this.onResetConfirmAuth,
  });

  @override
  List<Object?> get props => [
        loading,
        typingIndicators,
        readReceipts,
        sessionId,
        sessionName,
        sessionKey,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        typingIndicators: store.state.settingsStore.typingIndicatorsEnabled,
        readReceipts: selectReadReceiptsString(store.state.settingsStore.readReceipts),
        sessionId: store.state.authStore.user.deviceId ?? Values.EMPTY,
        sessionName: selectCurrentDeviceName(store),
        sessionKey: selectCurrentUserSessionKey(store),
        onDisabled: () => store.dispatch(addInProgress()),
        onResetConfirmAuth: () => store.dispatch(resetInteractiveAuth()),
        onToggleTypingIndicators: () => store.dispatch(
          toggleTypingIndicators(),
        ),
        onIncrementReadReceipts: () => store.dispatch(incrementReadReceipts()),
      );
}
