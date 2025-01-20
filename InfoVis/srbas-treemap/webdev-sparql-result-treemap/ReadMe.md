# Basel Financial Accounts (1535–1610) - Unified Treemap

This project provides a **single treemap** that combines both **income** (Einnahmen) and **expenditures** (Ausgaben). Each account is shown as a top‐level rectangle, and subaccounts appear when you zoom in.

## Features
1. **Year Filtering (1535–1610)**  
   Adjust the two sliders or manually press "Filter" to display only records whose `(year_from >= From && year_to <= To)`.

2. **Search**  
   Enter a subaccount keyword (case‐insensitive) and press **Search**. Matching rectangles are highlighted with a black outline.

3. **CSV Export**  
   Exports the currently filtered dataset into a CSV named `basel_data_{fromVal}-{toVal}.csv`.

4. **Net Balance**  
   Displays the overall net `(Incomes + Expenses)` for the filtered view:
   - **Green** if net ≥ 0
   - **Red** if net < 0  
   Also shows totals for incomes vs. absolute value of expenses.

5. **Zoom & Breadcrumb**  
   - Click on any rectangle with children to zoom in, revealing subaccounts.  
   - Click again on the same node (or its parent) to zoom out.  
   - A breadcrumb at the top indicates your current position in the hierarchy.

6. **Responsive Layout**  
   - Three columns: **left** (filters), **center** (treemap), **right** (about/info).  
   - Scales down nicely on smaller devices.

## File Structure
- **`index.html`**  
  Defines the layout (header, three columns, placeholders for treemap and legend, plus controls).
- **`style.css`**  
  Handles styling (responsive 3‐column layout, color palette, tooltips, breadcrumb, etc.).
- **`app.js`**  
  - Loads `sparql-result-accounts.json`.  
  - Filters data by year range.  
  - Builds a single **D3 treemap** with all accounts + subaccounts.  
  - Implements zoom transitions, search highlighting, CSV export, and net balance.  
- **`sparql-result-accounts.json`**  
  Your data file containing records with fields like `year_from`, `year_to`, `account_name`, `subaccount_name`, `amount`, etc.

## Usage
1. **Open `index.html`** in a modern browser (Chrome/Firefox). If you see errors about loading local files, serve via a simple HTTP server.
2. **Adjust Year Sliders** or press **Filter** to refine which records appear.
3. **Hover** a rectangle to see tooltips (sum, years, account, etc.).
4. **Click** a rectangle with children to zoom in or out. Follow the breadcrumb to track where you are in the hierarchy.
5. **Search** for a subaccount keyword and see it outlined in black.
6. **Export CSV** to download the filtered data.

## Customization
- **Color Scale**: In `app.js`, `colorScale` is set to `d3.schemeTableau10` by default. Adjust or replace with any D3 color scheme.
- **Tooltip Fields**: Add or remove row details in the `.html(...)` part of `on("mouseover", ...)`.
- **Net Balance**: You can remove or refine the logic if you prefer a different approach.

## Known Considerations
- For large sets of subaccounts, the treemap can get cluttered. You could **reintroduce** aggregator logic if you prefer to hide small subaccounts, but this code intentionally shows **all** subaccounts at once.
- Negative or zero values might appear in the data. The code takes absolute values for rectangle sizes but uses the sign to compute net balance.

## License
This project is provided as an example; feel free to adapt or expand it for your research or educational needs.
