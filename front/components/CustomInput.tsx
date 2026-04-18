import React, { useState } from 'react';
import { View, TextInput, TouchableOpacity, Text, StyleSheet, TextInputProps } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Controller, Control, FieldValues, Path } from 'react-hook-form';
import { colors, sizes } from '../constants/helpers';

interface CustomInputProps<T extends FieldValues> extends TextInputProps {
  control: Control<T>;
  name: Path<T>;
  iconName: keyof typeof Ionicons.glyphMap;
  placeholder: string;
  secureTextEntry?: boolean;
}

export default function CustomInput<T extends FieldValues>({ control, name, iconName, placeholder, secureTextEntry, ...props }: CustomInputProps<T>) {
  const [isSecure, setIsSecure] = useState(secureTextEntry);

  return (
    <Controller
      control={control}
      name={name}
      render={({ field: { onChange, onBlur, value }, fieldState: { error } }) => (
        <>
          <View style={[styles.inputContainer, error && styles.inputError]}>
            <Ionicons name={iconName} size={20} color={colors.secondary} style={styles.inputIcon} />
            <TextInput
              style={styles.input}
              placeholder={placeholder}
              placeholderTextColor={colors.secondary}
              value={value}
              onChangeText={onChange}
              onBlur={onBlur}
              secureTextEntry={isSecure}
              textAlign="left"
              autoCapitalize={props.autoCapitalize || "none"}
              {...props}
            />
            {secureTextEntry && (
              <TouchableOpacity style={styles.eyeIcon} onPress={() => setIsSecure(!isSecure)}>
                <Ionicons name={isSecure ? "eye-off-outline" : "eye-outline"} size={20} color={colors.secondary} />
              </TouchableOpacity>
            )}
          </View>
          {error && <Text style={styles.errorText}>{error.message}</Text>}
        </>
      )}
    />
  );
}

import { customInputStyles as styles } from '../sheets/components/custom-input.styles';
