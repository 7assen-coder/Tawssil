import React from 'react';
// eslint-disable-next-line no-unused-vars
import { Grid, /* eslint-disable-line no-unused-vars */ Card, /* eslint-disable-line no-unused-vars */ CardContent, /* eslint-disable-line no-unused-vars */ Typography, /* eslint-disable-line no-unused-vars */ Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper } from '@mui/material';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import './Budget.css';

const Budget = () => {
  // بيانات تجريبية
  const budgetData = {
    total: 150000,
    change: 5.2,
    expenses: [
      { category: 'رواتب الموظفين', amount: 45000, change: -2.1 },
      { category: 'تكاليف التشغيل', amount: 25000, change: 3.5 },
      { category: 'التسويق', amount: 15000, change: 8.2 },
      { category: 'الصيانة', amount: 10000, change: -1.5 },
      { category: 'أخرى', amount: 5000, change: 0 }
    ]
  };

  return (
    <div className="budget-page">
      <h1 className="page-title">الميزانية</h1>
      
      <div className="budget-container">
        <div className="budget-card">
          <h2>إجمالي الميزانية</h2>
          <div className="budget-amount">{budgetData.total.toLocaleString()} دج</div>
          <div className={`budget-change ${budgetData.change >= 0 ? 'positive' : 'negative'}`}>
            {budgetData.change >= 0 ? <TrendingUpIcon /> : <TrendingDownIcon />}
            {Math.abs(budgetData.change)}%
          </div>
        </div>
        
        <div className="budget-card">
          <h2>المصروفات الشهرية</h2>
          <div className="budget-amount">
            {budgetData.expenses.reduce((sum, exp) => sum + exp.amount, 0).toLocaleString()} دج
          </div>
        </div>
      </div>

      <div className="budget-chart">
        <h2>تحليل المصروفات</h2>
        {/* هنا سيتم إضافة الرسم البياني لاحقاً */}
      </div>

      <TableContainer component={Paper} className="budget-table">
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>الفئة</TableCell>
              <TableCell align="right">المبلغ</TableCell>
              <TableCell align="right">التغيير</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {budgetData.expenses.map((expense, index) => (
              <TableRow key={index}>
                <TableCell>{expense.category}</TableCell>
                <TableCell align="right">{expense.amount.toLocaleString()} دج</TableCell>
                <TableCell align="right">
                  <div className={`budget-change ${expense.change >= 0 ? 'positive' : 'negative'}`}>
                    {expense.change >= 0 ? <TrendingUpIcon /> : <TrendingDownIcon />}
                    {Math.abs(expense.change)}%
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </div>
  );
};

export default Budget;
