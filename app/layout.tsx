import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Black Socks - Premium Quality Socks',
  description: 'Discover our premium collection of black socks. Comfortable, durable, and stylish socks for every occasion.',
  keywords: 'black socks, premium socks, comfortable socks, dress socks, casual socks',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}