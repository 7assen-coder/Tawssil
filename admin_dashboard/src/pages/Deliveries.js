import React, { useState, useEffect } from 'react';
import {
  Grid, Card, CardContent, Typography, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, Chip, IconButton,
  TextField, Select, MenuItem, FormControl, InputLabel,
  Box, Button, Dialog, DialogTitle, DialogContent, Tabs, Tab
} from '@mui/material';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import CancelIcon from '@mui/icons-material/Cancel';
import SearchIcon from '@mui/icons-material/Search';
import VisibilityIcon from '@mui/icons-material/Visibility';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';
import axios from 'axios';
import './Deliveries.css';

const Deliveries = () => {
  const [tab, setTab] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedItem, setSelectedItem] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [commandes, setCommandes] = useState([]);
  const [voyages, setVoyages] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [cmdRes, voyRes] = await Promise.all([
          axios.get('http://localhost:8000/api/commandes/commandes-list/'),
          axios.get('http://localhost:8000/api/commandes/voyages-list/'),
        ]);
        setCommandes(cmdRes.data);
        setVoyages(voyRes.data);
      } catch (err) {
        setCommandes([]);
        setVoyages([]);
      }
    };
    fetchData();
  }, []);

  // فلترة البيانات حسب البحث والحالة
  const filteredCommandes = commandes.filter(cmd => {
    return (
      (cmd.client_username?.includes(searchTerm) ||
        cmd.fournisseur_nom?.includes(searchTerm) ||
        cmd.livreur_username?.includes(searchTerm) ||
        cmd.chauffeur_username?.includes(searchTerm) ||
        String(cmd.id_commande).includes(searchTerm)) &&
      (statusFilter === 'all' || cmd.statut === statusFilter)
    );
  });

  const filteredVoyages = voyages.filter(voyage => {
    return (
      (voyage.voyageur_username?.includes(searchTerm) ||
        voyage.destination?.includes(searchTerm) ||
        String(voyage.id_voyage).includes(searchTerm)) &&
      (statusFilter === 'all' || voyage.statut === statusFilter)
    );
  });

  const getStatusChip = (status) => {
    switch (status) {
      case 'En attente':
        return <Chip icon={<AccessTimeIcon />} label="En attente" color="warning" size="small" />;
      case 'Acceptée':
        return <Chip icon={<CheckCircleIcon />} label="Acceptée" color="info" size="small" />;
      case 'En préparation':
        return <Chip icon={<LocalShippingIcon />} label="En préparation" color="primary" size="small" />;
      case 'En livraison':
        return <Chip icon={<LocalShippingIcon />} label="En livraison" color="primary" size="small" />;
      case 'Livrée':
        return <Chip icon={<CheckCircleIcon />} label="Livrée" color="success" size="small" />;
      case 'Annulée':
        return <Chip icon={<CancelIcon />} label="Annulée" color="error" size="small" />;
      default:
        return <Chip label={status} size="small" />;
    }
  };

  // دالة موحدة لعرض الحالة (للتوصيلة والرحلة)
  const getSituationChip = (situation) => {
    switch (situation) {
      case 'En attente':
        return <Chip icon={<AccessTimeIcon />} label="En attente" color="warning" size="small" />;
      case 'Acceptée':
        return <Chip icon={<CheckCircleIcon />} label="Acceptée" color="info" size="small" />;
      case 'En route':
        return <Chip icon={<LocalShippingIcon />} label="En route" color="primary" size="small" />;
      case 'Terminée':
        return <Chip icon={<CheckCircleIcon />} label="Terminée" color="success" size="small" />;
      case 'Annulée':
        return <Chip icon={<CancelIcon />} label="Annulée" color="error" size="small" />;
      default:
        return <Chip label={situation} size="small" />;
    }
  };

  // عرض التقييم بالنجوم
  const renderRating = (rating) => {
    if (!rating) return "-";
    return (
      <Box sx={{ display: 'flex', alignItems: 'center' }}>
        <Typography variant="body2" component="span" sx={{ mr: 1 }}>
          {rating}/5
        </Typography>
        <Box sx={{ display: 'flex', color: '#FFB400' }}>
          {[...Array(5)].map((_, i) => (
            <span key={i} style={{ color: i < Math.floor(rating) ? '#FFB400' : '#e0e0e0' }}>★</span>
          ))}
        </Box>
      </Box>
    );
  };

  // فتح نافذة التفاصيل
  const handleShowDetails = (item, type) => {
    setSelectedItem({ ...item, type });
    setDialogOpen(true);
  };

  // إغلاق نافذة التفاصيل
  const handleCloseDialog = () => {
    setDialogOpen(false);
    setSelectedItem(null);
  };

  return (
    <div className="deliveries-page">
      <h1 className="page-title">Gestion des livraisons</h1>
      <Box sx={{ bgcolor: 'white', borderRadius: '10px 10px 0 0', mb: 2 }}>
        <Tabs value={tab} onChange={(_, v) => setTab(v)} variant="fullWidth">
          <Tab label="Livraison" icon={<LocalShippingIcon />} />
          <Tab label="Course" icon={<DirectionsCarIcon />} />
        </Tabs>
      </Box>
      <div className="filters-container">
        <div className="search-box">
          <SearchIcon />
          <TextField
            variant="outlined"
            size="small"
            placeholder="Rechercher par client, fournisseur, numéro de commande ou livreur"
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
          />
        </div>
        {tab === 0 ? (
          <div className="filter-status">
            <FormControl variant="outlined" size="small">
              <InputLabel>Statut</InputLabel>
              <Select
                value={statusFilter}
                onChange={e => setStatusFilter(e.target.value)}
                label="Statut"
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="En attente">En attente</MenuItem>
                <MenuItem value="Acceptée">Acceptée</MenuItem>
                <MenuItem value="En préparation">En préparation</MenuItem>
                <MenuItem value="En livraison">En livraison</MenuItem>
                <MenuItem value="Livrée">Livrée</MenuItem>
                <MenuItem value="Annulée">Annulée</MenuItem>
              </Select>
            </FormControl>
          </div>
        ) : (
          <div className="filter-status">
            <FormControl variant="outlined" size="small">
              <InputLabel>Statut</InputLabel>
              <Select
                value={statusFilter}
                onChange={e => setStatusFilter(e.target.value)}
                label="Statut"
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="En attente">En attente</MenuItem>
                <MenuItem value="Acceptée">Acceptée</MenuItem>
                <MenuItem value="En route">En route</MenuItem>
                <MenuItem value="Terminée">Terminée</MenuItem>
                <MenuItem value="Annulée">Annulée</MenuItem>
              </Select>
            </FormControl>
          </div>
        )}
      </div>
      {tab === 0 ? (
        <TableContainer component={Paper} className="deliveries-table">
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>N° Commande</TableCell>
                <TableCell>Client</TableCell>
                <TableCell>Fournisseur</TableCell>
                <TableCell>Livreur/Chauffeur</TableCell>
                <TableCell>Date de la commande</TableCell>
                <TableCell>Adresse</TableCell>
                <TableCell>Prix du produit (MRU)</TableCell>
                <TableCell>Frais de livraison (MRU)</TableCell>
                <TableCell>Évaluation</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredCommandes.map(cmd => (
                <TableRow key={cmd.id_commande}>
                  <TableCell>{cmd.id_commande}</TableCell>
                  <TableCell>{cmd.client_username}</TableCell>
                  <TableCell>{cmd.fournisseur_nom}</TableCell>
                  <TableCell>{cmd.livreur_username ? cmd.livreur_username : (cmd.chauffeur_username ? cmd.chauffeur_username : '-')}</TableCell>
                  <TableCell>{cmd.date_commande}</TableCell>
                  <TableCell>{cmd.adresse_livraison}</TableCell>
                  <TableCell>{cmd.prix_produit} MRU</TableCell>
                  <TableCell>{cmd.frais_livraison} MRU</TableCell>
                  <TableCell>{renderRating(cmd.evaluation)}</TableCell>
                  <TableCell>{getStatusChip(cmd.statut)}</TableCell>
                  <TableCell>
                    <IconButton size="small" title="Voir les détails" onClick={() => handleShowDetails(cmd, 'commande')}>
                      <VisibilityIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
              {filteredCommandes.length === 0 && (
                <TableRow>
                  <TableCell colSpan={11} align="center">Aucun résultat trouvé</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      ) : (
        <TableContainer component={Paper} className="deliveries-table">
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>N° Voyage</TableCell>
                <TableCell>Voyageur</TableCell>
                <TableCell>Chauffeur</TableCell>
                <TableCell>Destination</TableCell>
                <TableCell>Date de départ</TableCell>
                <TableCell>Date d'arrivée</TableCell>
                <TableCell>Nombre de personnes</TableCell>
                <TableCell>Tarif du transport (MRU)</TableCell>
                <TableCell>Évaluation</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredVoyages.map(voyage => (
                <TableRow key={voyage.id_voyage}>
                  <TableCell>{voyage.id_voyage}</TableCell>
                  <TableCell>{voyage.voyageur_username}</TableCell>
                  <TableCell>{voyage.chauffeur_username || '-'}</TableCell>
                  <TableCell>{voyage.destination}</TableCell>
                  <TableCell>{voyage.date_depart}</TableCell>
                  <TableCell>{voyage.date_arrivee}</TableCell>
                  <TableCell>{voyage.nombre_personnes}</TableCell>
                  <TableCell>{voyage.tarif_transport} MRU</TableCell>
                  <TableCell>{renderRating(voyage.evaluation)}</TableCell>
                  <TableCell>{getSituationChip(voyage.statut)}</TableCell>
                  <TableCell>
                    <IconButton size="small" title="Voir les détails" onClick={() => { setSelectedItem(voyage); setDialogOpen(true); }}>
                      <VisibilityIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
              {filteredVoyages.length === 0 && (
                <TableRow>
                  <TableCell colSpan={11} align="center">Aucun résultat trouvé</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      )}
      {/* نافذة التفاصيل */}
      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle sx={{ fontWeight: 'bold', fontSize: 22, mb: 1, bgcolor: '#f5f5f5', borderBottom: '1px solid #eee' }}>
          <Box display="flex" alignItems="center" justifyContent="space-between">
            <Box display="flex" alignItems="center" gap={1}>
              {tab === 0 ? <LocalShippingIcon color="primary" /> : <DirectionsCarIcon color="primary" />}
              <span>{tab === 0 ? 'Détails de la livraison' : 'Détails du voyage'}</span>
            </Box>
            <Box>
              {tab === 0 && selectedItem && getStatusChip(selectedItem.statut)}
              {tab === 1 && selectedItem && getSituationChip(selectedItem.statut)}
            </Box>
          </Box>
        </DialogTitle>
        <DialogContent sx={{ bgcolor: '#fafbfc' }}>
          {selectedItem && tab === 0 && (
            <Box>
              <Grid container spacing={2}>
                <Grid item xs={12} md={6}>
                  <Card variant="outlined" sx={{ mb: 2, boxShadow: 3, borderRadius: 3, bgcolor: '#fafdff' }}>
                    <CardContent>
                      <Typography variant="h6" fontWeight={700} gutterBottom>Informations du client</Typography>
                      <Typography><b>Nom:</b> {selectedItem.client_username}</Typography>
                      <Typography><b>Adresse:</b> {selectedItem.adresse_livraison}</Typography>
                    </CardContent>
                  </Card>
                  <Card variant="outlined" sx={{ mb: 2, boxShadow: 3, borderRadius: 3, bgcolor: '#fafdff' }}>
                    <CardContent>
                      <Typography variant="h6" fontWeight={700} gutterBottom>Fournisseur et livreur</Typography>
                      <Typography><b>Fournisseur:</b> {selectedItem.fournisseur_nom}</Typography>
                      <Typography><b>Livreur/Chauffeur:</b> {selectedItem.livreur_username ? selectedItem.livreur_username : (selectedItem.chauffeur_username ? selectedItem.chauffeur_username : '-' )}</Typography>
                      {selectedItem.evaluation && (
                        <Box mt={1}>
                          <Typography><b>Évaluation:</b></Typography>
                          <Box display="flex" alignItems="center" mt={0.5}>
                            <Typography variant="body1" component="span" sx={{ mr: 1, fontWeight: 600 }}>
                              {selectedItem.evaluation}/5
                            </Typography>
                            <Box sx={{ display: 'flex', color: '#FFB400' }}>
                              {[...Array(5)].map((_, i) => (
                                <span key={i} style={{ color: i < Math.floor(selectedItem.evaluation) ? '#FFB400' : '#e0e0e0', fontSize: '20px' }}>★</span>
                              ))}
                            </Box>
                          </Box>
                        </Box>
                      )}
                    </CardContent>
                  </Card>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Card variant="outlined" sx={{ mb: 2, boxShadow: 3, borderRadius: 3, bgcolor: '#fafdff' }}>
                    <CardContent>
                      <Typography variant="h6" fontWeight={700} gutterBottom>Détails de la commande</Typography>
                      <Grid container spacing={1}>
                        <Grid item xs={6}><Typography><b>N° Commande:</b> {selectedItem.id_commande}</Typography></Grid>
                        <Grid item xs={6}><Typography><b>Date de la commande:</b> {selectedItem.date_commande}</Typography></Grid>
                        <Grid item xs={6}><Typography><b>Prix du produit:</b> {selectedItem.prix_produit} MRU</Typography></Grid>
                        <Grid item xs={6}><Typography><b>Frais de livraison:</b> {selectedItem.frais_livraison} MRU</Typography></Grid>
                        <Grid item xs={6}><Typography><b>Date de livraison estimée:</b> {selectedItem.date_livraison_estimee || '-'}</Typography></Grid>
                        <Grid item xs={6}><Typography><b>Date de livraison réelle:</b> {selectedItem.date_livraison_reelle || '-'}</Typography></Grid>
                      </Grid>
                    </CardContent>
                  </Card>
                  <Card variant="outlined" sx={{ mb: 2, boxShadow: 3, borderRadius: 3, bgcolor: '#fafdff' }}>
                    <CardContent>
                      <Typography variant="h6" fontWeight={700} gutterBottom>Instructions spéciales</Typography>
                      <Typography>{selectedItem.instructions_speciales || '-'}</Typography>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>
              {selectedItem.origin && selectedItem.destination && (
                <Card variant="outlined" sx={{ mt: 2 }}>
                  <CardContent>
                    <Typography variant="h6" fontWeight={700} color="success.main" gutterBottom>Itinéraire sur la carte</Typography>
                    <iframe
                      title="خريطة التوصيل"
                      width="100%"
                      height="300"
                      style={{ border: 0, borderRadius: 8 }}
                      loading="lazy"
                      allowFullScreen
                      src={`https://www.google.com/maps/embed/v1/directions?key=YOUR_GOOGLE_MAPS_API_KEY&origin=${encodeURIComponent(selectedItem.origin)}&destination=${encodeURIComponent(selectedItem.destination)}`}
                    />
                    <Box mt={1} textAlign="left">
                      <a href={`https://www.google.com/maps/dir/?api=1&origin=${encodeURIComponent(selectedItem.origin)}&destination=${encodeURIComponent(selectedItem.destination)}`} target="_blank" rel="noopener noreferrer" style={{ color: '#1976d2', textDecoration: 'underline', fontWeight: 600 }}>
                        Ouvrir dans Google Maps
                      </a>
                    </Box>
                  </CardContent>
                </Card>
              )}
            </Box>
          )}
          {selectedItem && tab === 1 && (
            <Box>
              <Grid container spacing={2}>
                <Grid item xs={12} md={6}>
                  <Card variant="outlined" sx={{ mb: 2, boxShadow: 3, borderRadius: 3, bgcolor: '#fafdff' }}>
                    <CardContent>
                      <Typography variant="h6" fontWeight={700} gutterBottom>Informations du voyageur</Typography>
                      <Typography><b>Voyageur:</b> {selectedItem.voyageur_username}</Typography>
                      <Typography><b>Chauffeur:</b> {selectedItem.chauffeur_username || '-'}</Typography>
                      <Typography><b>Destination:</b> {selectedItem.destination}</Typography>
                      <Typography><b>Nombre de personnes:</b> {selectedItem.nombre_personnes}</Typography>
                      <Typography><b>Évaluation:</b> {selectedItem.evaluation ? `${selectedItem.evaluation}/5` : '-'}</Typography>
                    </CardContent>
                  </Card>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Card variant="outlined" sx={{ mb: 2, boxShadow: 3, borderRadius: 3, bgcolor: '#fafdff' }}>
                    <CardContent>
                      <Typography variant="h6" fontWeight={700} gutterBottom>Détails du voyage</Typography>
                      <Grid container spacing={1}>
                        <Grid item xs={6}><Typography><b>N° Voyage:</b> {selectedItem.id_voyage}</Typography></Grid>
                        <Grid item xs={6}><Typography><b>Date de départ:</b> {selectedItem.date_depart}</Typography></Grid>
                        <Grid item xs={6}><Typography><b>Date d'arrivée:</b> {selectedItem.date_arrivee}</Typography></Grid>
                        <Grid item xs={6}><Typography><b>Tarif du transport:</b> {selectedItem.tarif_transport} MRU</Typography></Grid>
                      </Grid>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>
              {selectedItem.origin && selectedItem.destination && (
                <Card variant="outlined" sx={{ mt: 2 }}>
                  <CardContent>
                    <Typography variant="h6" fontWeight={700} color="success.main" gutterBottom>Itinéraire sur la carte</Typography>
                    <iframe
                      title="خريطة الرحلة"
                      width="100%"
                      height="300"
                      style={{ border: 0, borderRadius: 8 }}
                      loading="lazy"
                      allowFullScreen
                      src={`https://www.google.com/maps/embed/v1/directions?key=YOUR_GOOGLE_MAPS_API_KEY&origin=${encodeURIComponent(selectedItem.origin)}&destination=${encodeURIComponent(selectedItem.destination)}`}
                    />
                    <Box mt={1} textAlign="left">
                      <a href={`https://www.google.com/maps/dir/?api=1&origin=${encodeURIComponent(selectedItem.origin)}&destination=${encodeURIComponent(selectedItem.destination)}`} target="_blank" rel="noopener noreferrer" style={{ color: '#1976d2', textDecoration: 'underline', fontWeight: 600 }}>
                        Ouvrir dans Google Maps
                      </a>
                    </Box>
                  </CardContent>
                </Card>
              )}
            </Box>
          )}
        </DialogContent>
        <Box display="flex" justifyContent="flex-end" p={2}>
          <Button onClick={handleCloseDialog} color="primary">Fermer</Button>
        </Box>
      </Dialog>
    </div>
  );
};

export default Deliveries; 