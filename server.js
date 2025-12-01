const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Sample data
let customers = [
  { id: 1, name: 'Alia Johnson', email: 'alice@acmecorp.com', company: 'Acme Corp', status: 'active' },
  { id: 2, name: 'Bob Smith', email: 'bob@techstart.io', company: 'TechStart', status: 'active' },
  { id: 3, name: 'Charlie Brown', email: 'charlie@innovate.com', company: 'Innovate Inc', status: 'inactive' },
  { id: 4, name: 'Diana Prince', email: 'diana@wondertech.com', company: 'WonderTech', status: 'active' },
  { id: 5, name: 'Eve Martinez', email: 'eve@cloudnine.com', company: 'Cloud Nine', status: 'active' }
];

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Customer API is running',
    timestamp: new Date().toISOString() 
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// GET all customers
app.get('/api/customers', (req, res) => {
  res.json({ success: true, count: customers.length, data: customers });
});

// GET customer by ID
app.get('/api/customers/:id', (req, res) => {
  const customer = customers.find(c => c.id === parseInt(req.params.id));
  if (!customer) {
    return res.status(404).json({ success: false, error: 'Customer not found' });
  }
  res.json({ success: true, data: customer });
});

// POST new customer
app.post('/api/customers', (req, res) => {
  const { name, email, company, status } = req.body;
  
  if (!name || !email || !company) {
    return res.status(400).json({ success: false, error: 'Name, email, and company are required' });
  }
  
  const newCustomer = {
    id: customers.length + 1,
    name,
    email,
    company,
    status: status || 'active'
  };
  
  customers.push(newCustomer);
  res.status(201).json({ success: true, data: newCustomer });
});

// PUT update customer
app.put('/api/customers/:id', (req, res) => {
  const customer = customers.find(c => c.id === parseInt(req.params.id));
  if (!customer) {
    return res.status(404).json({ success: false, error: 'Customer not found' });
  }
  
  const { name, email, company, status } = req.body;
  if (name) customer.name = name;
  if (email) customer.email = email;
  if (company) customer.company = company;
  if (status) customer.status = status;
  
  res.json({ success: true, data: customer });
});

// DELETE customer
app.delete('/api/customers/:id', (req, res) => {
  const index = customers.findIndex(c => c.id === parseInt(req.params.id));
  if (index === -1) {
    return res.status(404).json({ success: false, error: 'Customer not found' });
  }
  
  const deleted = customers.splice(index, 1);
  res.json({ success: true, data: deleted[0] });
});

app.get('/api/customers/status/:status', (req, res) => {
  const filtered = customers.filter(c => c.status === req.params.status);
  res.json({ success: true, count: filtered.length, data: filtered });
});

// IMPORTANT: Listen on 0.0.0.0 for containers!
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Customer API running on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🌐 Listening on 0.0.0.0:${PORT}`);
});