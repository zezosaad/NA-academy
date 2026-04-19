import React, { createContext, useCallback, useContext, useMemo, useState } from 'react';
import { Modal, Pressable, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { colors, sizes } from '../constants/helpers';

type DialogButtonStyle = 'default' | 'cancel' | 'destructive';

interface DialogButton {
  text: string;
  style?: DialogButtonStyle;
  onPress?: () => void | Promise<void>;
}

interface DialogOptions {
  title: string;
  message?: string;
  buttons?: DialogButton[];
}

interface AppDialogContextValue {
  showDialog: (options: DialogOptions) => void;
}

const AppDialogContext = createContext<AppDialogContextValue | null>(null);

export function AppDialogProvider({ children }: { children: React.ReactNode }) {
  const [visible, setVisible] = useState(false);
  const [options, setOptions] = useState<DialogOptions | null>(null);

  const showDialog = useCallback((next: DialogOptions) => {
    setOptions(next);
    setVisible(true);
  }, []);

  const close = useCallback(() => {
    setVisible(false);
  }, []);

  const buttons = options?.buttons?.length ? options.buttons : [{ text: 'OK' }];

  const handlePress = useCallback(async (button: DialogButton) => {
    close();
    await button.onPress?.();
  }, [close]);

  const value = useMemo(() => ({ showDialog }), [showDialog]);

  return (
    <AppDialogContext.Provider value={value}>
      {children}
      <Modal visible={visible} transparent animationType="fade" onRequestClose={close}>
        <Pressable style={styles.overlay} onPress={close}>
          <Pressable style={styles.modal} onPress={(e) => e.stopPropagation()}>
            <Text style={styles.title}>{options?.title}</Text>
            {!!options?.message && <Text style={styles.message}>{options.message}</Text>}
            <View style={styles.actions}>
              {buttons.map((button, index) => (
                <TouchableOpacity
                  key={`${button.text}-${index}`}
                  style={[
                    styles.button,
                    button.style === 'destructive' && styles.buttonDestructive,
                    button.style === 'cancel' && styles.buttonCancel,
                  ]}
                  onPress={() => handlePress(button)}
                >
                  <Text
                    style={[
                      styles.buttonText,
                      button.style === 'destructive' && styles.buttonTextDestructive,
                    ]}
                  >
                    {button.text}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </Pressable>
        </Pressable>
      </Modal>
    </AppDialogContext.Provider>
  );
}

export function useAppDialog() {
  const context = useContext(AppDialogContext);
  if (!context) {
    throw new Error('useAppDialog must be used within AppDialogProvider');
  }
  return context;
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.45)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: sizes.lg,
  },
  modal: {
    width: '100%',
    maxWidth: 420,
    backgroundColor: colors.card,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.border,
    padding: sizes.lg,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: sizes.xs,
    textAlign: 'center',
  },
  message: {
    fontSize: 14,
    color: colors.textSecondary,
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: sizes.lg,
  },
  actions: {
    gap: sizes.sm,
  },
  button: {
    height: 46,
    borderRadius: 10,
    backgroundColor: colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
  },
  buttonCancel: {
    backgroundColor: colors.border,
  },
  buttonDestructive: {
    backgroundColor: `${colors.danger}14`,
    borderWidth: 1,
    borderColor: `${colors.danger}45`,
  },
  buttonText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#fff',
  },
  buttonTextDestructive: {
    color: colors.danger,
  },
});
