const PDFDocument = require('pdfkit');

// ─────────────────────────────────────────────────────
// pdfService.js
// Generates professional PDF reports for leads
// ─────────────────────────────────────────────────────

function generateLeadReport(lead, mortgageResult, scoringResult) {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({
        size: 'A4',
        margin: 50,
        info: {
          Title: `LoanTrack Report — ${lead.first_name} ${lead.last_name}`,
          Author: 'LoanTrack',
          Subject: 'Mortgage Lead Report',
        },
      });

      const chunks = [];
      doc.on('data', chunk => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // ── COLORS ────────────────────────────────────
      const NAVY   = '#0B2545';
      const TEAL   = '#0D7377';
      const GRAY   = '#6B7E8F';
      const LIGHT  = '#F0F5F9';
      const BLACK  = '#1C1C1E';

      // ── HELPER FUNCTIONS ──────────────────────────

      function drawRect(x, y, w, h, color) {
        doc.rect(x, y, w, h).fill(color);
      }

      function sectionTitle(text, y) {
        doc.moveTo(50, y).lineTo(545, y).stroke(TEAL);
        doc.fontSize(11).fillColor(NAVY).font('Helvetica-Bold')
          .text(text.toUpperCase(), 50, y + 8, { characterSpacing: 1 });
        return y + 30;
      }

      function infoRow(label, value, x, y, width = 220) {
        doc.fontSize(8).fillColor(GRAY).font('Helvetica')
          .text(label.toUpperCase(), x, y);
        doc.fontSize(10).fillColor(BLACK).font('Helvetica-Bold')
          .text(value || '—', x, y + 12, { width });
        return y + 36;
      }

      function statBox(label, value, x, y, color = TEAL) {
        drawRect(x, y, 145, 60, LIGHT);
        doc.fontSize(8).fillColor(GRAY).font('Helvetica')
          .text(label.toUpperCase(), x + 10, y + 10, { width: 125 });
        doc.fontSize(16).fillColor(color).font('Helvetica-Bold')
          .text(value, x + 10, y + 24, { width: 125 });
      }

      // ── HEADER ────────────────────────────────────
      drawRect(0, 0, 595, 100, NAVY);

      doc.fontSize(24).fillColor('white').font('Helvetica-Bold')
        .text('LoanTrack', 50, 28);
      doc.fontSize(10).fillColor('#7DD3FC').font('Helvetica')
        .text('Mortgage Lead Report', 50, 58);

      // Date top right
      doc.fontSize(9).fillColor('white').font('Helvetica')
        .text(new Date().toLocaleDateString('en-US', {
          year: 'numeric', month: 'long', day: 'numeric'
        }), 400, 42, { width: 145, align: 'right' });

      // ── LEAD NAME BANNER ──────────────────────────
      drawRect(0, 100, 595, 60, TEAL);
      doc.fontSize(20).fillColor('white').font('Helvetica-Bold')
        .text(`${lead.first_name} ${lead.last_name}`, 50, 118);

      // Status badge
      const statusColors = {
        new: '#3B82F6',
        contacted: '#F59E0B',
        qualified: '#8B5CF6',
        closed: '#10B981',
        lost: '#EF4444',
      };
      const statusColor = statusColors[lead.status] || TEAL;
      drawRect(430, 115, 115, 26, statusColor);
      doc.fontSize(10).fillColor('white').font('Helvetica-Bold')
        .text((lead.status || 'New').toUpperCase(), 430, 123,
          { width: 115, align: 'center' });

      let y = 185;

      // ── CONTACT INFORMATION ───────────────────────
      y = sectionTitle('Contact Information', y);

      infoRow('Full Name', `${lead.first_name} ${lead.last_name}`, 50, y);
      infoRow('Email Address', lead.email, 290, y);
      y += 36;
      infoRow('Phone Number', lead.phone || '—', 50, y);
      infoRow('Date Added', new Date(lead.date_added).toLocaleDateString(), 290, y);
      y += 50;

      // ── FINANCIAL PROFILE ─────────────────────────
      y = sectionTitle('Financial Profile', y);

      infoRow('Annual Income', lead.income
        ? `$${Number(lead.income).toLocaleString()}` : '—', 50, y);
      infoRow('Total Debt', lead.debt
        ? `$${Number(lead.debt).toLocaleString()}` : '—', 290, y);
      y += 36;
      infoRow('Credit Score', lead.credit_score
        ? `${lead.credit_score}` : '—', 50, y);
      infoRow('Employment', lead.employment_status || 'Employed', 290, y);
      y += 50;

      // ── MORTGAGE SUMMARY ──────────────────────────
      if (mortgageResult) {
        y = sectionTitle('Mortgage Calculation', y);

        statBox('Loan Amount',
          `$${Number(lead.loan_amount).toLocaleString()}`,
          50, y, NAVY);
        statBox('Monthly Payment',
          `$${mortgageResult.monthlyPayment.toLocaleString()}`,
          205, y, TEAL);
        statBox('Total Interest',
          `$${Number(mortgageResult.totalInterest).toLocaleString()}`,
          360, y, '#B45309');

        y += 80;

        infoRow('Total Payment',
          `$${Number(mortgageResult.totalPayment).toLocaleString()}`,
          50, y);
        infoRow('Loan to Value',
          `${mortgageResult.loanToValue}%`,
          290, y);
        y += 50;
      }

      // ── RISK SCORE ────────────────────────────────
      if (scoringResult) {
        y = sectionTitle('AI Risk Assessment', y);

        // Score bar background
        drawRect(50, y, 495, 20, '#E5E7EB');

        // Score bar fill
        const scoreWidth = Math.round((scoringResult.score / 100) * 495);
        const scoreColor = scoringResult.score >= 80 ? '#10B981'
          : scoringResult.score >= 60 ? '#F59E0B'
          : '#EF4444';
        drawRect(50, y, scoreWidth, 20, scoreColor);

        // Score label
        doc.fontSize(10).fillColor(NAVY).font('Helvetica-Bold')
          .text(`Risk Score: ${scoringResult.score}/100 — ${scoringResult.riskLabel}`,
            50, y + 28);
        y += 55;

        // Recommendation box
        drawRect(50, y, 495, 50, LIGHT);
        doc.fontSize(8).fillColor(GRAY).font('Helvetica')
          .text('RECOMMENDATION', 60, y + 8);
        doc.fontSize(9).fillColor(BLACK).font('Helvetica')
          .text(scoringResult.recommendation, 60, y + 20, { width: 475 });
        y += 65;

        // Score breakdown
        if (scoringResult.breakdown && scoringResult.breakdown.length > 0) {
          doc.fontSize(9).fillColor(NAVY).font('Helvetica-Bold')
            .text('Score Breakdown:', 50, y);
          y += 16;

          scoringResult.breakdown.forEach(item => {
            doc.fontSize(9).fillColor(BLACK).font('Helvetica')
              .text(`${item.factor}`, 60, y, { width: 200 });
            doc.fontSize(9).fillColor(TEAL).font('Helvetica-Bold')
              .text(`${item.points} pts`, 270, y, { width: 80 });
            doc.fontSize(9).fillColor(GRAY).font('Helvetica')
              .text(item.note, 360, y, { width: 185 });
            y += 16;
          });
          y += 10;
        }

        // Loan recommendation
        if (scoringResult.loanRecommendation) {
          drawRect(50, y, 495, 60, LIGHT);
          doc.fontSize(8).fillColor(GRAY).font('Helvetica')
            .text('RECOMMENDED LOAN TYPE', 60, y + 8);
          doc.fontSize(11).fillColor(NAVY).font('Helvetica-Bold')
            .text(scoringResult.loanRecommendation.type, 60, y + 22);
          doc.fontSize(9).fillColor(GRAY).font('Helvetica')
            .text(`Suggested Rate: ${scoringResult.loanRecommendation.suggestedRate}`,
              60, y + 38);
          y += 75;
        }
      }

      // ── NOTES ─────────────────────────────────────
      if (lead.notes) {
        y = sectionTitle('Notes', y);
        drawRect(50, y, 495, 50, LIGHT);
        doc.fontSize(9).fillColor(BLACK).font('Helvetica')
          .text(lead.notes, 60, y + 10, { width: 475, height: 30 });
        y += 65;
      }

      // ── FOOTER ────────────────────────────────────
      drawRect(0, 780, 595, 62, NAVY);
      doc.fontSize(8).fillColor('#7DD3FC').font('Helvetica')
        .text('Generated by LoanTrack — Mortgage Lead Management System',
          50, 795, { width: 495, align: 'center' });
      doc.fontSize(8).fillColor('white').font('Helvetica')
        .text(`Report generated on ${new Date().toISOString()}`,
          50, 810, { width: 495, align: 'center' });

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
}

module.exports = { generateLeadReport };