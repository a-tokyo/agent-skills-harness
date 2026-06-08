import { Footer, Layout, Navbar } from 'nextra-theme-docs'
import { Head } from 'nextra/components'
import { getPageMap } from 'nextra/page-map'
import 'nextra-theme-docs/style.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: {
    default: 'Agent Skills Harness',
    template: '%s – Agent Skills Harness'
  },
  description:
    'A factory for building production-grade agent skills — benchmarked against gold standards, autonomously improved via autoresearch, and verified by multi-agent consensus.'
}

const REPO = 'https://github.com/a-tokyo/agent-skills-harness'

const navbar = (
  <Navbar
    logo={<b>Agent Skills Harness</b>}
    projectLink={REPO}
  />
)

const footer = (
  <Footer>
    MIT {new Date().getFullYear()} © <a href="https://github.com/a-tokyo">Ahmed Tokyo</a>.
  </Footer>
)

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" dir="ltr" suppressHydrationWarning>
      <Head />
      <body>
        <Layout
          navbar={navbar}
          footer={footer}
          pageMap={await getPageMap()}
          docsRepositoryBase={`${REPO}/tree/main/site`}
        >
          {children}
        </Layout>
      </body>
    </html>
  )
}
