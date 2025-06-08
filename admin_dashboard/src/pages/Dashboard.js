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
import StatCard from '../components/StatCard';
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
      });

    fetch('http://localhost:8000/api/commandes/recent-voyages/')
      .then(res => res.json())
      .then(data => {
        setRecentVoyages(data);
      });
  }, []);

  useEffect(() => {
    // في بيئة الإنتاج، ستستخدم هذه الدوال لجلب البيانات الحقيقية
    // getDashboardStats().then(response => setStats(response.data));
    // getPendingDrivers().then(response => setPendingDrivers(response.data));
    // getDeliveries('recent').then(response => setRecentDeliveries(response.data));

    // بيانات تجريبية للعرض
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
      
      <div className="tables-grid">
        <div className="card">
          <h2 className="section-title">Dernières demandes de chauffeurs</h2>
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>N° Voyage</th>
                  <th>Client</th>
                  <th>Destination</th>
                  <th>Tarif</th>
                  <th>Poids disponible</th>
                  <th>Date départ</th>
                </tr>
              </thead>
              <tbody>
                {recentVoyages.map((voyage) => (
                  <tr key={voyage.id_voyage}>
                    <td>{voyage.id_voyage}</td>
                    <td>{voyage.voyageur_username || '-'}</td>
                    <td>{voyage.destination}</td>
                    <td>{voyage.tarif_transport} MRU</td>
                    <td>{voyage.poids_disponible} kg</td>
                    <td>{voyage.date_depart ? new Date(voyage.date_depart).toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
        
        <div className="card">
          <h2 className="section-title">Dernières livraisons</h2>
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>N°</th>
                  <th>Nom livreur</th>
                  <th>Client</th>
                  <th>Date</th>
                  <th>Adresse</th>
                  <th>Montant</th>
                  <th>Statut</th>
                </tr>
              </thead>
              <tbody>
                {recentLivreurLivraisons.map((cmd) => (
                  <tr key={cmd.id_commande}>
                    <td>{cmd.id_commande}</td>
                    <td>{cmd.livreur_username || '-'}</td>
                    <td>{cmd.client_username || '-'}</td>
                    <td>{new Date(cmd.date_commande).toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: 'numeric' })}</td>
                    <td>{cmd.adresse_livraison}</td>
                    <td>{cmd.montant_total} MRU</td>
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
    </div>
  );
}

export default Dashboard;