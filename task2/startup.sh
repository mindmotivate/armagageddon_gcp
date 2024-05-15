#!/bin/bash
# Update and install Apache2
apt update
apt install -y apache2

# Start and enable Apache2
systemctl start apache2
systemctl enable apache2

# Set image URL
IMAGE_URL="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExMGJ0Z2w2eGdsdXA5cHZ1ZXQ5NXFiMmo2dDcxb3d4M3R2eTl0NnowbCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/OQ4EsiCV54vtQbvav5/giphy.gif"

# Create a simple HTML page with a lighthearted note about the project requirements
cat <<EOF > /var/www/html/index.html
<html><body>
<h2>Welcome to your custom website.</h2>
<h3>Class 5.5 Armageddon Task 2:</h3>
<ol>
<li>Create a VPC with Terraform</li>
<li>Add a VM within your VPC using Terraform</li>
<li>Make sure the VM serves this homepage</li>
<li>Get that VM a public link</li>
<li>Don't forget to Git Push your script to your Github!</li>
</ol>
<p>And while you're at it, enjoy this funny GIF:</p>
<img src="$IMAGE_URL">
</body></html>
EOF
