import { StyleSheet, Dimensions } from 'react-native';

const { height } = Dimensions.get('window');

export const authLayoutStyles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#f8f9fc',
    },
    gradient: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        height: height * 0.4,
    },
});
