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
    voyagesData: []
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

    // Fetch recent livraisons (deliveries) data
    fetch('http://localhost:8000/api/commandes/recent-livreur-livraisons/')
      .then(res => res.json())
      .then(data => {
        setRecentLivreurLivraisons(data);
        
        // Process data for charts - group by date and calculate daily totals
        const deliveriesByDate = data.reduce((acc, item) => {
          const date = new Date(item.date_commande).toLocaleDateString('fr-FR', { month: 'short', day: 'numeric' });
          
          if (!acc[date]) {
            acc[date] = {
              date: date,
              count: 0,
              montant: 0
            };
          }
          
          acc[date].count += 1;
          acc[date].montant += parseFloat(item.montant_total) || 0;
          
          return acc;
        }, {});
        
        // Convert to array and sort by date
        const chartData = Object.values(deliveriesByDate)
          .sort((a, b) => {
            // Extract day number for sorting
            const dayA = parseInt(a.date.match(/\d+/)[0]);
            const dayB = parseInt(b.date.match(/\d+/)[0]);
            return dayA - dayB;
          })
          .slice(-7); // Get last 7 days
        
        setStatisticsData(prev => ({
          ...prev,
          dailyDeliveries: chartData
        }));
      });

    // Fetch recent voyages data
    fetch('http://localhost:8000/api/commandes/recent-voyages/')
      .then(res => res.json())
      .then(data => {
        setRecentVoyages(data);
        
        // Process data for charts - group by date and calculate daily totals
        const voyagesByDate = data.reduce((acc, item) => {
          const date = new Date(item.date_depart).toLocaleDateString('fr-FR', { month: 'short', day: 'numeric' });
          
          if (!acc[date]) {
            acc[date] = {
              date: date,
              count: 0,
              distance: 0,
              tarif: 0
            };
          }
          
          acc[date].count += 1;
          acc[date].tarif += parseFloat(item.tarif_transport) || 0;
          
          // Extract distance if available
          if (item.distance) {
            acc[date].distance += parseFloat(item.distance) || 0;
          }
          
          return acc;
        }, {});
        
        // Convert to array and sort by date
        const chartData = Object.values(voyagesByDate)
          .sort((a, b) => {
            // Extract day number for sorting
            const dayA = parseInt(a.date.match(/\d+/)[0]);
            const dayB = parseInt(b.date.match(/\d+/)[0]);
            return dayA - dayB;
          })
          .slice(-10); // Get last 10 days
        
        setStatisticsData(prev => ({
          ...prev,
          voyagesData: chartData
        }));
      });
  }, []);

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

  // Calculate totals for chart footers
  const totalDailyDeliveries = statisticsData.dailyDeliveries.reduce(
    (sum, item) => sum + (item.count || 0), 
    0
  );
  
  const totalVoyages = statisticsData.voyagesData.reduce(
    (sum, item) => sum + (item.count || 0), 
    0
  );
  
  const totalVoyagesTarif = statisticsData.voyagesData.reduce(
    (sum, item) => sum + (item.tarif || 0), 
    0
  );

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
                      dataKey="date" 
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
                      dataKey="count" 
                      name="Nombre de livraisons" 
                      stroke="#1976d2" 
                      strokeWidth={2}
                      dot={{ r: 4, fill: "#1976d2" }}
                      activeDot={{ r: 6, fill: "#1976d2" }}
                    />
                    </LineChart>
                  </ResponsiveContainer>
              </div>
              <div className="chart-footer">
                <span>Données des 7 derniers jours</span>
                <span>Total: {totalDailyDeliveries} livraisons</span>
              </div>
            </div>
            
            {/* Voyages quotidiens */}
            <div className="statistic-card">
              <h3 className="statistic-card-header">Voyages quotidiens</h3>
              <div className="line-chart-container">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart 
                    data={statisticsData.voyagesData}
                    margin={{ top: 5, right: 20, bottom: 20, left: 0 }}
                  >
                    <defs>
                      <linearGradient id="colorCount" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#ff9800" stopOpacity={0.8}/>
                        <stop offset="95%" stopColor="#ff9800" stopOpacity={0.1}/>
                      </linearGradient>
                      <linearGradient id="colorTarif" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#43a047" stopOpacity={0.8}/>
                        <stop offset="95%" stopColor="#43a047" stopOpacity={0.1}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#eee" vertical={false} />
                    <XAxis 
                      dataKey="date" 
                      axisLine={false} 
                      tickLine={false}
                      tick={{ fontSize: 11 }}
                    />
                    <YAxis 
                      yAxisId="left"
                      axisLine={false} 
                      tickLine={false}
                      tick={{ fontSize: 11 }}
                    />
                    <YAxis 
                      yAxisId="right"
                      orientation="right"
                      axisLine={false} 
                      tickLine={false}
                      tick={{ fontSize: 11 }}
                    />
                    <Tooltip content={<CustomTooltip />} />
                    <Area 
                      yAxisId="left"
                      type="monotone" 
                      dataKey="count" 
                      name="Nombre de voyages" 
                      stroke="#ff9800" 
                      fillOpacity={1}
                      fill="url(#colorCount)"
                      strokeWidth={2}
                    />
                    <Line 
                      yAxisId="right"
                      type="monotone" 
                      dataKey="tarif" 
                      name="Tarif (DZD)" 
                      stroke="#43a047" 
                      strokeWidth={2}
                      dot={{ r: 4, fill: "#43a047" }}
                      activeDot={{ r: 6, fill: "#43a047" }}
                    />
                  </AreaChart>
                  </ResponsiveContainer>
              </div>
              <div className="chart-footer">
                <span>Total: {totalVoyages} voyages</span>
                <span>Tarif total: {Math.round(totalVoyagesTarif)} DZD</span>
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