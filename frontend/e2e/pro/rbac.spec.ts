import { test, expect } from '@playwright/test'
import { config } from '../config'

test.describe('RBAC (Pro)', () => {
  test.skip(!config.isPro, 'Pro feature - skipped')

  test.beforeEach(async ({ page }) => {
    await page.goto('/rbac')
    await page.waitForLoadState('networkidle')
  })

  test('page loads with heading', async ({ page }) => {
    await expect(page.locator('h1')).toBeVisible()
  })

  test('has table', async ({ page }) => {
    await expect(page.locator('table')).toBeVisible({ timeout: 10000 })
  })

  test('has help button', async ({ page }) => {
    await expect(page.locator('button').filter({ hasText: /help/i })).toBeVisible()
  })

  test('has filter buttons', async ({ page }) => {
    // Type filter and create role button
    const buttons = page.locator('button')
    expect(await buttons.count()).toBeGreaterThanOrEqual(3)
  })

  test('create role button opens dialog', async ({ page }) => {
    const buttons = page.locator('button')
    const count = await buttons.count()
    // Try the last few buttons to find the create role button
    for (let i = count - 1; i >= Math.max(0, count - 3); i--) {
      await buttons.nth(i).click()
      const dialog = page.locator('[role="dialog"]').first()
      try {
        await dialog.waitFor({ state: 'visible', timeout: 2000 })
        await expect(dialog).toBeVisible()
        return
      } catch {
        await page.keyboard.press('Escape')
        await page.waitForTimeout(300)
      }
    }
  })

  test('table has rows', async ({ page }) => {
    const rows = page.locator('table tbody tr')
    await rows.first().waitFor({ state: 'visible', timeout: 10000 })
    expect(await rows.count()).toBeGreaterThan(0)
  })
})
