# 📝 **Task № 1: Diagnosing and Resolving Disk Space Issues**

## 📋 **1. Issue Description**
The customer is complaining that there is no more space on the server. First, try to expand the disk space. If that's not possible, then let me know why. If you have expanded the space (or failed to do so) and the disk is still full, then try to remove unnecessary files.

## 🛠️ **Steps for Diagnosing and Solving the Issue**

---

### **1️⃣ Initial Issue and Disk Expansion**

**Action:**
- Accessed the AWS Management Console.
- Navigated to the **EC2 Dashboard**.
- Selected the instance and modified the **EBS volume** attached to the instance.
- Increased the disk size from its initial size to **70GB**.

**Result:**
- After resizing the disk, the connection to the instance was successfully re-established.

---

### **2️⃣ Identifying Disk Space Usage**

**Command:**
```bash
df -h
```

**Key Observations:**
- Check for **40% disk usage** in the output of **df -h**.
- Identify the partition or filesystem with insufficient space.

---

### **3️⃣ Identifying and Removing Large Files**

#### **3.1 Finding large files**

**Command:**
```bash
sudo find / -type f -size +500M -exec du -h {} + | sort -rh | head -n 10
```

**Explanation:**
- This command lists files larger than **500MB** and sorts them in descending order.

---

#### **3.2 Deleting large files**

**Command:**
```bash
sudo rm [file_path]
```

**Explanation:**
- Deleted the identified large file to free up space.

**Result:**
- Available disk space increased, allowing normal operations on the server.

---

### **4️⃣ Final Validation**

**Command:**
```bash
df -h
```

**Key Observations:**
- Confirm that free disk space has increased.

---

# 📝 **Task № 2: Diagnosing and Resolving High CPU Usage Issues**

## 📋 **1. Issue Description**
The customer is again complaining that the server has high CPU usage. Try to determine what is causing the load and eliminate the problem.

---

## 🛠️ **Steps for Diagnosing and Solving the Issue**

---

### **1️⃣ Identifying the CPU Issue**

#### **1.1 Detecting high CPU usage**

**Command:**
```bash
top
```

**Key Observations:**
- CPU usage was consistently at **99-100%**.
- The process **yes** was consuming **99% of the CPU**.
- **Steal time (st) = ~5%**, which indicates that AWS was throttling CPU usage due to the exhaustion of CPU credits.

---

#### **1.2 Checking AWS CPU Credit Balance**

**Command:**
```bash
aws cloudwatch get-metric-statistics \  
  --region eu-west-1 \  
  --namespace AWS/EC2 \  
  --metric-name CPUCreditBalance \  
  --dimensions Name=InstanceId,Value=i-03a5be9f102de7dfb \  
  --statistics Average \  
  --period 300 \  
  --start-time "$(date -v-12H -u +"%Y-%m-%dT%H:%M:%SZ")" \  
  --end-time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
```

**Key Observations:**
- **CPUCreditBalance = 0**, indicating that all CPU credits had been exhausted.
- As a result, AWS began throttling CPU usage, as shown by the **steal time (st) > 0%**.

---

### **2️⃣ Diagnosing the Cause of CPU Load**

#### **2.1 Checking active processes with high CPU usage**

**Command:**
```bash
top
```

**Observation:**
- The main culprit was the **yes** process, which was consuming most of the CPU.

---

#### **2.2 Listing top processes consuming CPU**

**Command:**
```bash
ps aux --sort=-%cpu | head -n 10
```

**Result:**
- The **yes** process was using **99.9% of the CPU**.

---

#### **2.3 Finding the process path and parent process**

**Command:**
```bash
ps -fp 1746
```

**Result:**
- The parent process is **/bin/bash**, which is running the script **/etc/kernel/preinst.d/lll.sh**.

---

### **3️⃣ Stopping Processes and Mitigating the Issue**

#### **3.1 Kill the 'yes' process**

**Command:**
```bash
pkill -9 -f yes
```

---

#### **3.2 Kill the bash process executing lll.sh**

**Command:**
```bash
pkill -9 -f /etc/kernel/preinst.d/lll.sh
```

---

### **5️⃣ Cleaning Up Script Files and State**

#### **5.1 Review the lll.sh script**

**Command:**
```bash
sudo nano /etc/kernel/preinst.d/lll.sh
```

**Update script to be empty:**
```bash
#!/bin/bash
```

---

# 📝 **Task № 3: Server Restart Issue Analysis and Resolution**

## 📋 **1. Issue Description**
The customer's servers are restarting, and we don't know why.

---

## 🔍 **2. Diagnostics and Analysis**

### **1️⃣ Systemd Logs Analysis**

**Command Used:**
```bash
journalctl -b -1 -e
```

**Findings:**
- The logs revealed that systemd triggered the shutdown.target, final.target, and reboot.target, indicating that the reboots were initiated programmatically.

---

### **2️⃣ Crontab Analysis**

**Commands Used:**
```bash
sudo crontab -l
sudo cat /etc/crontab
sudo ls /etc/cron.d/
```

**Findings:**
- A misconfigured cron job was found in the **root user crontab**:
  ```
  */30 * * * * /sbin/reboot
  ```

---

### **3️⃣ Systemd Timer Analysis**

**Command Used:**
```bash
systemctl list-timers --all
```

**Findings:**
- No systemd timers were found that would trigger a system reboot.

---

## 🛠️ **3. Resolution**

### 🗑️ **1️⃣ Remove the Problematic Cron Job**

**Command Used:**
```bash
sudo crontab -e
```

**Action Taken:**
- The problematic cron job was removed.

---

## 🔐 **4. Security Recommendations**

### **1️⃣ Restrict Access to Crontab**

- Limit access to sudo crontab -e for specific users.
- Create a /etc/cron.deny file and add restricted users to it:
```bash
echo 'ssm-user' >> /etc/cron.deny
```

---


