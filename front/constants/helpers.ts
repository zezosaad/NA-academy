import { Dimensions } from "react-native";

export const { width, height } = Dimensions.get("window");

export const sizes = {
    xs: 5,
    sm: 10,
    md: 15,
    lg: 20,
    xl: 25,
    xxl: 30,
    xxxl: 40
}

export const colors = {
    primary: "#007bff",
    secondary: "#6c757d",
    success: "#28a745",
    danger: "#dc3545",
    warning: "#ffc107",
    info: "#17a2b8",
    light: "#f8f9fa",
    dark: "#343a40",
    background: "#F8F9FC",
    card: "#FFFFFF",
    border: "#E2E8F0",
    textPrimary: "#1E293B",
    textSecondary: "#64748B",
}

export const fonts = {
    regular: "Regular",
    medium: "Medium",
    bold: "Bold",
}
