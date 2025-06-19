import React, { useEffect, useState } from 'react';
import PersonIcon from '@mui/icons-material/Person';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import PaidIcon from '@mui/icons-material/Paid';
import SupportAgentIcon from '@mui/icons-material/SupportAgent';
import RestaurantIcon from '@mui/icons-material/Restaurant';
import LocalPharmacyIcon from '@mui/icons-material/LocalPharmacy';
import StoreMallDirectoryIcon from '@mui/icons-material/StoreMallDirectory';
import StorefrontIcon from '@mui/icons-material/Storefront';
import TwoWheelerIcon from '@mui/icons-material/TwoWheeler';
import DriveEtaIcon from '@mui/icons-material/DriveEta';
import GroupIcon from '@mui/icons-material/Group';
import InsightsIcon from '@mui/icons-material/Insights';
import BarChartIcon from '@mui/icons-material/BarChart';
import StatCard from '../components/StatCard';
import { 
  LineChart, Line, XAxis, YAxis, CartesianGrid, 
  Tooltip, ResponsiveContainer, AreaChart, Area
} from 'recharts';
import './Dashboard.css';

const Dashboard = () => {
  const [stats, setStats] = useState({});
  const [isLoading, setIsLoading] = useState(true);
  const [lastMonthDeliveries, setLastMonthDeliveries] = useState(null);
  const [yesterdayRevenue, setYesterdayRevenue] = useState(null);
  const [providersStats, setProvidersStats] = useState(null);
  const [supportDetails, setSupportDetails] = useState(null);
  const [usersStats, setUsersStats] = useState(null);
  const [recentLivreurLivraisons, setRecentLivreurLivraisons] = useState([]);
  const [recentVoyages, setRecentVoyages] = useState([]);
  const [activeTab, setActiveTab] = useState(0);
  const [statisticsData, setStatisticsData] = useState({
    deliveries: [],
    revenue: [],
    dailyDeliveries: [],
    weeklyRevenue: []
  });

  // عدد الطلبات في الشهر الماضي (يمكنك تعديله لاحقاً أو جلبه من API)
  const percentageChange = lastMonthDeliveries === null || lastMonthDeliveries === 0
    ? 0
    : Math.round(((stats.activeDeliveries - lastMonthDeliveries) / lastMonthDeliveries) * 100);

  // حساب نسبة التغير في الإيرادات اليومية
  const revenueChange = yesterdayRevenue === null || yesterdayRevenue === 0
    ? 0
    : Math.round(((stats.todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100);

  useEffect(() => {
    let pendingDriversFetched = false;
    let activeDeliveriesFetched = false;
    let lastMonthFetched = false;
    let yesterdayRevenueFetched = false;

    fetch('http://localhost:8000/api/pending-drivers-count/')
      .then(res => res.json())
      .then(data => {
        setStats(prev => ({
          ...prev,
          pendingDrivers: data.pending_drivers
        }));
        pendingDriversFetched = true;
        if (pendingDriversFetched && activeDeliveriesFetched && lastMonthFetched && yesterdayRevenueFetched) setIsLoading(false);
      });

    fetch('http://localhost:8000/api/commandes/active-deliveries-count/')
      .then(res => res.json())
      .then(data => {
        setStats(prev => ({
          ...prev,
          activeDeliveries: data.active_deliveries || 0
        }));
        activeDeliveriesFetched = true;
        if (pendingDriversFetched && activeDeliveriesFetched && lastMonthFetched && yesterdayRevenueFetched) setIsLoading(false);
      })
      .catch(error => {
        console.error('Error fetching active deliveries:', error);
        setStats(prev => ({
          ...prev,
          activeDeliveries: 0
        }));
        activeDeliveriesFetched = true;
        if (pendingDriversFetched && activeDeliveriesFetched && lastMonthFetched && yesterdayRevenueFetched) setIsLoading(false);
      });

    fetch('http://localhost:8000/api/commandes/last-month-active-deliveries-count/')
      .then(res => res.json())
      .then(data => {
        setLastMonthDeliveries(data.last_month_active_deliveries);
        lastMonthFetched = true;
        if (pendingDriversFetched && activeDeliveriesFetched && lastMonthFetched && yesterdayRevenueFetched) setIsLoading(false);
      });

    fetch('http://localhost:8000/api/commandes/today-revenue/')
      .then(res => res.json())
      .then(data => {
        setStats(prev => ({
          ...prev,
          todayRevenue: data.today_revenue
        }));
        if (pendingDriversFetched && activeDeliveriesFetched && lastMonthFetched && yesterdayRevenueFetched) setIsLoading(false);
      });

    fetch('http://localhost:8000/api/commandes/yesterday-revenue/')
      .then(res => res.json())
      .then(data => {
        setYesterdayRevenue(data.yesterday_revenue);
        yesterdayRevenueFetched = true;
        if (pendingDriversFetched && activeDeliveriesFetched && lastMonthFetched && yesterdayRevenueFetched) setIsLoading(false);
      });

    fetch('http://localhost:8000/api/providers-stats/')
      .then(res => res.json())
      .then(data => {
        setProvidersStats(data);
      });

    fetch('http://localhost:8000/api/messaging/support-tickets-count/')
      .then(res => res.json())
      .then(data => {
        setStats(prev => ({
          ...prev,
          supportTickets: data.total
        }));
        setSupportDetails(data);
      });

    fetch('http://localhost:8000/api/users-stats/')
      .then(res => res.json())
      .then(data => {
        setUsersStats(data);
        setStats(prev => ({
          ...prev,
          totalUsers: data.total
        }));
      });

    fetch('http://localhost:8000/api/commandes/recent-livreur-livraisons/')
      .then(res => res.json())
      .then(data => {
        setRecentLivreurLivraisons(data);
        
        // تحويل البيانات للرسوم البيانية
        const chartData = data.map(item => ({
          id: item.id_commande,
          name: item.client_username || 'Client',
          montant: item.montant_total,
          date: new Date(item.date_commande).toLocaleDateString('fr-FR', { month: 'short', day: 'numeric' })
        }));
        
        setStatisticsData(prev => ({
          ...prev,
          deliveries: chartData
        }));
      });

    fetch('http://localhost:8000/api/commandes/recent-voyages/')
      .then(res => res.json())
      .then(data => {
        setRecentVoyages(data);
        
        // تحويل البيانات للرسوم البيانية
        const chartData = data.map(item => ({
          id: item.id_voyage,
          name: item.voyageur_username || 'Voyageur',
          tarif: item.tarif_transport,
          date: new Date(item.date_depart).toLocaleDateString('fr-FR', { month: 'short', day: 'numeric' })
        }));
        
        setStatisticsData(prev => ({
          ...prev,
          revenue: chartData
        }));
      });

    // Fetch daily deliveries data for trend chart
    fetch('http://localhost:8000/api/commandes/daily-deliveries/')
      .then(res => res.json())
      .then(data => {
        // If the API doesn't exist yet, this is simulated data
        // In a real implementation, this would come from the backend
        const dailyData = data.daily_data || generateDailyDeliveriesData();
        
        setStatisticsData(prev => ({
          ...prev,
          dailyDeliveries: dailyData
        }));
      })
      .catch(() => {
        // Fallback to simulated data if API doesn't exist
        const simulatedData = generateDailyDeliveriesData();
        setStatisticsData(prev => ({
          ...prev,
          dailyDeliveries: simulatedData
        }));
      });

    // Fetch weekly revenue data for trend chart
    fetch('http://localhost:8000/api/commandes/weekly-revenue/')
      .then(res => res.json())
      .then(data => {
        // If the API doesn't exist yet, this is simulated data
        // In a real implementation, this would come from the backend
        const weeklyData = data.weekly_data || generateWeeklyRevenueData();
        
        setStatisticsData(prev => ({
          ...prev,
          weeklyRevenue: weeklyData
        }));
      })
      .catch(() => {
        // Fallback to simulated data if API doesn't exist
        const simulatedData = generateWeeklyRevenueData();
        setStatisticsData(prev => ({
          ...prev,
          weeklyRevenue: simulatedData
        }));
      });
  }, []);

  // Generate simulated data for daily deliveries (to be replaced with real API data)
  const generateDailyDeliveriesData = () => {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const currentDate = new Date();
    const currentDay = currentDate.getDay(); // 0 = Sunday, 1 = Monday, ...
    
    return days.map((day, index) => {
      // Generate data with realistic fluctuations
      const baseValue = 120; // Base number of deliveries
      const dayOffset = (index + 1) % 7; // Adjust for days of week (Monday = 0)
      
      // Create a pattern: higher on weekends, lower on Tuesdays
      let multiplier = 1;
      if (dayOffset === 5 || dayOffset === 6) { // Weekend (Sat, Sun)
        multiplier = 1.5;
      } else if (dayOffset === 1) { // Tuesday
        multiplier = 0.7;
      } else if (dayOffset === 3) { // Thursday
        multiplier = 1.2;
      }
      
      // Add some randomness
      const randomFactor = 0.8 + Math.random() * 0.4; // Between 0.8 and 1.2
      
      // Calculate final value with some randomness
      const value = Math.round(baseValue * multiplier * randomFactor);
      
      // Highlight the current day
      const isToday = (dayOffset === currentDay);
      
      return {
        name: day,
        deliveries: value,
        isToday: isToday
      };
    });
  };

  // Generate simulated data for weekly revenue (to be replaced with real API data)
  const generateWeeklyRevenueData = () => {
    const weeks = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
    
    return weeks.map((week, index) => {
      // Generate data with realistic fluctuations
      const baseRevenue = 5000; // Base revenue
      
      // Create a pattern: growth trend with a dip in week 3
      let multiplier = 1 + (index * 0.15); // Growth trend
      if (index === 2) { // Week 3 dip
        multiplier = 0.9;
      }
      
      // Add some randomness
      const randomFactor = 0.9 + Math.random() * 0.2; // Between 0.9 and 1.1
      
      // Calculate final value with some randomness
      const value = Math.round(baseRevenue * multiplier * randomFactor);
      
      return {
        name: week,
        revenue: value
      };
    });
  };

  useEffect(() => {
    setIsLoading(false);
  }, []);

  if (isLoading) {
    return <div className="loading">Chargement en cours...</div>;
  }

  // استخراج أعداد المزودين حسب النوع من البيانات الجديدة
  const fournisseurs = providersStats && providersStats.fournisseurs ? providersStats.fournisseurs : [];
  const totalProviders = fournisseurs.length;
  const restaurantCount = fournisseurs.filter(f => f.type === 'Restaurant').length;
  const pharmacyCount = fournisseurs.filter(f => f.type === 'Pharmacie').length;
  const supermarketCount = fournisseurs.filter(f => f.type === 'Supermarché').length;
  
  // Custom tooltip for charts
  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      return (
        <div className="custom-tooltip">
          <p className="tooltip-label">{`${label}`}</p>
          {payload.map((entry, index) => (
            <p key={`item-${index}`} style={{ color: entry.color || entry.stroke }}>
              {`${entry.name}: ${entry.value}`}
            </p>
          ))}
        </div>
      );
    }
    return null;
  };

  const isSmallScreen = window.innerWidth <= 768;

  return (
    <div className="dashboard-page">
      <h1 className="page-title">Tableau de bord</h1>
      
      <div className="dashboard-grid">
        <StatCard 
          title="Demandes de chauffeurs en attente" 
          value={stats.pendingDrivers} 
          icon={<PersonIcon fontSize="large" />} 
          colorClass="orange"
        />
        <StatCard 
          title="Livraisons actives" 
          value={stats.activeDeliveries !== undefined ? stats.activeDeliveries : 0} 
          icon={<LocalShippingIcon fontSize="large" />} 
          change={
            percentageChange === 0
              ? "0%"
              : (percentageChange > 0 ? `+${percentageChange}%` : `${percentageChange}%`)
          }
          colorClass="blue"
        />
        <StatCard 
          title="Revenus du jour" 
          value={`$${typeof stats.todayRevenue === 'number' && !isNaN(stats.todayRevenue) ? stats.todayRevenue : 0}`} 
          icon={<PaidIcon fontSize="large" />} 
          change={
            revenueChange === 0
              ? "0%"
              : (revenueChange > 0 ? `+${revenueChange}%` : `${revenueChange}%`)
          }
          colorClass="green"
        />
        <StatCard 
          title="Fournisseurs enregistrés" 
          value={providersStats ? (
            <div style={{width: '100%', textAlign: 'center'}}>
              <div style={{fontWeight: 'bold', fontSize: 32, marginBottom: 8}}>{totalProviders}</div>
              <div style={{display: 'flex', justifyContent: 'space-around', alignItems: 'center', width: '100%'}}>
                <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 80}}>
                  <RestaurantIcon style={{color: '#1976d2', fontSize: 28}} />
                  <span style={{fontSize: 14, color: '#444'}}>Restaurants</span>
                  <span style={{fontWeight: 'bold', fontSize: 18}}>{restaurantCount}</span>
                </div>
                <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 80}}>
                  <LocalPharmacyIcon style={{color: '#43a047', fontSize: 28}} />
                  <span style={{fontSize: 14, color: '#444'}}>Pharmacies</span>
                  <span style={{fontWeight: 'bold', fontSize: 18}}>{pharmacyCount}</span>
                </div>
                <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 80}}>
                  <StoreMallDirectoryIcon style={{color: '#fbc02d', fontSize: 28}} />
                  <span style={{fontSize: 14, color: '#444'}}>Supermarchés</span>
                  <span style={{fontWeight: 'bold', fontSize: 18}}>{supermarketCount}</span>
                </div>
              </div>
            </div>
          ) : '...'}
          icon={<StorefrontIcon fontSize="large" />} 
        />
        <StatCard 
          title="Tickets de support" 
          value={supportDetails ? (
            <div style={{width: '100%'}}>
              <div style={{fontWeight: 'bold', fontSize: 32, marginBottom: 8, textAlign: 'center'}}>{supportDetails.total}</div>
              <div style={{display: 'flex', justifyContent: 'space-around', alignItems: 'flex-start', width: '100%', gap: 16}}>
                {/* Clients */}
                <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 120}}>
                  <PersonIcon style={{color: '#1976d2', fontSize: 28}} />
                  <span style={{fontSize: 14, color: '#444'}}>Clients</span>
                  <span style={{fontWeight: 'bold', fontSize: 18}}>{supportDetails.clients.count_unread || 0}</span>
                </div>
                {/* Drivers (Chauffeur + Livreur) */}
                <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 120}}>
                  <div style={{display: 'flex', alignItems: 'center', gap: 4}}>
                    <DriveEtaIcon style={{color: '#43a047', fontSize: 28}} />
                    <TwoWheelerIcon style={{color: '#fbc02d', fontSize: 24}} />
                  </div>
                  <span style={{fontSize: 14, color: '#444', marginTop: 2}}>Drivers</span>
                  <span style={{fontWeight: 'bold', fontSize: 18}}>{(supportDetails.chauffeurs.count_unread || 0) + (supportDetails.livreurs.count_unread || 0)}</span>
                </div>
              </div>
            </div>
          ) : stats.supportTickets}
          icon={<SupportAgentIcon fontSize="large" />} 
        />
        <StatCard 
          title="Utilisateurs" 
          value={usersStats ? (
            <div style={{width: '100%', textAlign: 'center'}}>
              <div style={{fontWeight: 'bold', fontSize: 32, marginBottom: 8}}>{usersStats.total}</div>
              <div style={{display: 'flex', justifyContent: 'space-around', alignItems: 'center', width: '100%'}}>
                <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 80}}>
                  <PersonIcon style={{color: '#1976d2', fontSize: 28}} />
                  <span style={{fontSize: 14, color: '#444', fontWeight: 'bold'}}>Clients</span>
                  <span style={{fontWeight: 'bold', fontSize: 18}}>{usersStats.clients.count}</span>
                </div>
                <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 80}}>
                  <DriveEtaIcon style={{color: '#43a047', fontSize: 28}} />
                  <span style={{fontSize: 14, color: '#444', fontWeight: 'bold'}}>Chauffeurs</span>
                  <span style={{fontWeight: 'bold', fontSize: 18}}>{usersStats.drivers.chauffeurs.count}</span>
                </div>
                <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 80}}>
                  <TwoWheelerIcon style={{color: '#fbc02d', fontSize: 28}} />
                  <span style={{fontSize: 14, color: '#444', fontWeight: 'bold'}}>Livreurs</span>
                  <span style={{fontWeight: 'bold', fontSize: 18}}>{usersStats.drivers.livreurs.count}</span>
                </div>
              </div>
            </div>
          ) : stats.totalUsers}
          icon={<GroupIcon fontSize="large" />} 
        />
      </div>
      
      {/* Statistics Section */}
      <div className="statistics-section">
        <div className="statistics-header">
          <h2 className="section-title">Statistiques des activités</h2>
          <div className="statistics-tabs">
            <button 
              className={`statistics-tab-btn ${activeTab === 0 ? 'active' : ''}`}
              onClick={() => setActiveTab(0)}
            >
              <InsightsIcon fontSize="small" />
              <span>Statistiques</span>
            </button>
            <button 
              className={`statistics-tab-btn ${activeTab === 1 ? 'active' : ''}`}
              onClick={() => setActiveTab(1)}
            >
              <BarChartIcon fontSize="small" />
              <span>Données</span>
            </button>
          </div>
        </div>
        
        {activeTab === 0 ? (
          <div className="statistics-cards">
            {/* Livraisons quotidiennes */}
            <div className="statistic-card">
              <h3 className="statistic-card-header">Livraisons quotidiennes</h3>
              <div className="line-chart-container">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart 
                    data={statisticsData.dailyDeliveries} 
                    margin={{ top: 5, right: 20, bottom: 20, left: 0 }}
                  >
                    <CartesianGrid strokeDasharray="3 3" stroke="#eee" vertical={false} />
                    <XAxis 
                      dataKey="name" 
                      axisLine={false} 
                      tickLine={false}
                      tick={{ fontSize: 11 }}
                    />
                    <YAxis 
                      axisLine={false} 
                      tickLine={false} 
                      tick={{ fontSize: 11 }}
                    />
                    <Tooltip content={<CustomTooltip />} />
                    <Line 
                      type="monotone" 
                      dataKey="deliveries" 
                      name="Livraisons" 
                      stroke="#1976d2" 
                      strokeWidth={2}
                      dot={{ r: 4, fill: "#1976d2" }}
                      activeDot={{ r: 6, fill: "#1976d2" }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
              <div className="chart-footer">
                <span>Tendance hebdomadaire</span>
                <span>Total: {statisticsData.dailyDeliveries.reduce((sum, item) => sum + item.deliveries, 0)}</span>
              </div>
            </div>
            
            {/* Revenus hebdomadaires */}
            <div className="statistic-card">
              <h3 className="statistic-card-header">Revenus hebdomadaires</h3>
              <div className="line-chart-container">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart 
                    data={statisticsData.weeklyRevenue}
                    margin={{ top: 5, right: 20, bottom: 20, left: 0 }}
                  >
                    <defs>
                      <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#43a047" stopOpacity={0.8}/>
                        <stop offset="95%" stopColor="#43a047" stopOpacity={0.1}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#eee" vertical={false} />
                    <XAxis 
                      dataKey="name" 
                      axisLine={false} 
                      tickLine={false}
                      tick={{ fontSize: 11 }}
                    />
                    <YAxis 
                      axisLine={false} 
                      tickLine={false}
                      tick={{ fontSize: 11 }}
                    />
                    <Tooltip content={<CustomTooltip />} />
                    <Area 
                      type="monotone" 
                      dataKey="revenue" 
                      name="Revenus" 
                      stroke="#43a047" 
                      fillOpacity={1}
                      fill="url(#colorRevenue)"
                      strokeWidth={2}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
              <div className="chart-footer">
                <span>Tendance mensuelle</span>
                <span>Total: ${statisticsData.weeklyRevenue.reduce((sum, item) => sum + item.revenue, 0)}</span>
              </div>
            </div>
          </div>
        ) : (
          <div className="statistics-cards">
            {/* Dernières demandes de chauffeurs */}
            <div className="statistic-card">
              <h3 className="statistic-card-header">Dernières demandes de chauffeurs</h3>
              <div className="table-container">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>N° Voyage</th>
                      <th>Client</th>
                      {!isSmallScreen && <th>Destination</th>}
                      <th>Tarif</th>
                      <th>Date départ</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recentVoyages.map((voyage) => (
                      <tr key={voyage.id_voyage}>
                        <td>{voyage.id_voyage}</td>
                        <td>{voyage.voyageur_username || '-'}</td>
                        {!isSmallScreen && <td>{voyage.destination}</td>}
                        <td>{voyage.tarif_transport}</td>
                        <td>{voyage.date_depart ? new Date(voyage.date_depart).toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: 'numeric' }) : '-'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
            
            {/* Dernières livraisons */}
            <div className="statistic-card">
              <h3 className="statistic-card-header">Dernières livraisons</h3>
              <div className="table-container">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>N°</th>
                      {!isSmallScreen && <th>Livreur</th>}
                      <th>Client</th>
                      <th>Date</th>
                      <th>Montant</th>
                      <th>Statut</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recentLivreurLivraisons.map((cmd) => (
                      <tr key={cmd.id_commande}>
                        <td>{cmd.id_commande}</td>
                        {!isSmallScreen && <td>{cmd.livreur_username || '-'}</td>}
                        <td>{cmd.client_username || '-'}</td>
                        <td>{new Date(cmd.date_commande).toLocaleDateString('fr-FR', { month: 'short', day: 'numeric' })}</td>
                        <td>{cmd.montant_total}</td>
                        <td>
                          <span className={`status-badge status-${cmd.statut.replace(/\s/g, '').toLowerCase()}`}>{cmd.statut}</span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default Dashboard;