package com.sipnudge.sipnudge

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface

object WidgetRingRenderer {

    fun renderGauge(
        progress: Double,
        expectedPercent: Double,
        percentageString: String,
        recentAddedAmount: Int?,
        sizePx: Int = 320
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // 7.5pt stroke at 82pt frame translates to ~0.098f ratio
        val strokeWidth = sizePx * 0.098f
        val padding = strokeWidth / 2f + 4f
        val oval = RectF(padding, padding, sizePx - padding, sizePx - padding)

        // In iOS: Circle().trim(from: 0.0, to: 0.833).rotationEffect(Angle(degrees: 300))
        // Starts at 300 degrees (1 o'clock) and sweeps 300 degrees clockwise (leaving 60 deg gap at 12 o'clock)
        val startAngle = 300f
        val maxSweep = 300f

        // 1. Background track arc
        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            strokeCap = Paint.Cap.ROUND
            color = Color.parseColor("#EBEEF2")
        }
        canvas.drawArc(oval, startAngle, maxSweep, false, trackPaint)

        // 2. Expected schedule target arc (Amber/Yellow #F5B91E)
        if (expectedPercent > 0) {
            val sweepTarget = (Math.min(expectedPercent / 100.0, 1.0) * maxSweep).toFloat()
            if (sweepTarget > 0) {
                val targetPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    this.strokeWidth = strokeWidth
                    strokeCap = Paint.Cap.ROUND
                    color = Color.parseColor("#F5B91E")
                }
                canvas.drawArc(oval, startAngle, sweepTarget, false, targetPaint)
            }
        }

        // 3. Actual water intake progress arc (Gradient Blue #B4D9FF to #1C8DBB)
        if (progress > 0) {
            val sweepActual = (Math.min(progress, 1.0) * maxSweep).toFloat()
            if (sweepActual > 0) {
                val gradient = LinearGradient(
                    sizePx / 2f, 0f,
                    sizePx / 2f, sizePx.toFloat(),
                    Color.parseColor("#B4D9FF"),
                    Color.parseColor("#1C8DBB"),
                    Shader.TileMode.CLAMP
                )
                val actualPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    this.strokeWidth = strokeWidth
                    strokeCap = Paint.Cap.ROUND
                    shader = gradient
                }
                canvas.drawArc(oval, startAngle, sweepActual, false, actualPaint)
            }
        }

        // 4. Center Text: Percentage & Optional "+ xxx ml" indicator
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
            color = Color.parseColor("#172645")
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif", Typeface.BOLD)
            letterSpacing = -0.02f
        }

        val centerX = sizePx / 2f
        val centerY = sizePx / 2f

        if (recentAddedAmount != null && recentAddedAmount > 0) {
            textPaint.textSize = sizePx * 0.22f
            canvas.drawText(percentageString, centerX, centerY - sizePx * 0.04f, textPaint)

            val badgePaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
                color = Color.parseColor("#A37A52")
                textAlign = Paint.Align.CENTER
                textSize = sizePx * 0.11f
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
            }
            canvas.drawText("+$recentAddedAmount ml", centerX, centerY + sizePx * 0.16f, badgePaint)
        } else {
            textPaint.textSize = sizePx * 0.28f
            val yPos = centerY - (textPaint.descent() + textPaint.ascent()) / 2
            canvas.drawText(percentageString, centerX, yPos, textPaint)
        }

        return bitmap
    }
}
