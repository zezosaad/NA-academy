import React from 'react'
import { Tabs } from 'expo-router'
import { Octicons } from '@expo/vector-icons'
import { colors } from '../../constants/helpers'

export default function TabsLayout() {
    return (
        <Tabs
            screenOptions={{
                headerShown: false,
                tabBarActiveTintColor: colors.primary,
                tabBarInactiveTintColor: colors.secondary,
                tabBarStyle: {
                    backgroundColor: colors.card,
                    borderTopColor: colors.border,
                    height: 70,
                    paddingBottom: 8,
                    paddingTop: 4,
                },
                tabBarLabelStyle: {
                    fontSize: 11,
                    fontWeight: '600',
                },
            }}
        >
            <Tabs.Screen
                name="index"
                options={{
                    title: "Home",
                    tabBarIcon: ({ color }) => (
                        <Octicons name="home" size={22} color={color} />
                    ),
                }}
            />
            <Tabs.Screen
                name="subjects"
                options={{
                    title: "Subjects",
                    tabBarIcon: ({ color }) => (
                        <Octicons name="book" size={22} color={color} />
                    ),
                }}
            />
            <Tabs.Screen
                name="exams"
                options={{
                    title: "Exams",
                    tabBarIcon: ({ color }) => (
                        <Octicons name="checklist" size={22} color={color} />
                    ),
                }}
            />
            <Tabs.Screen
                name="chat"
                options={{
                    title: "Chat",
                    tabBarIcon: ({ color }) => (
                        <Octicons name="comment-discussion" size={22} color={color} />
                    ),
                }}
            />
            <Tabs.Screen
                name="profile"
                options={{
                    title: "Profile",
                    tabBarIcon: ({ color }) => (
                        <Octicons name="person" size={22} color={color} />
                    ),
                }}
            />
        </Tabs>

    )
}