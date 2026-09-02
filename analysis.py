import pandas as pd
import matplotlib.pyplot as plt

# 1. Load the CSV file exported from pgAdmin
df = pd.read_csv('vw_supply_chain_performance.csv')

# 2. Print basic statistical KPIs
total_orders = len(df)
delayed_orders = df['is_delayed'].sum()
otd_rate = ((total_orders - delayed_orders) / total_orders) * 100

print(f"Total Orders Evaluated: {total_orders:,}")
print(f"On-Time Delivery Rate: {otd_rate:.2f}%")
print(f"Late Delivery Rate: {100 - otd_rate:.2f}%")

# 3. Plot On-Time vs Delayed Deliveries Bar Chart
plt.figure(figsize=(7, 5))
df['is_delayed'].value_counts().plot(kind='bar', color=['#2ca02c', '#d62728'])
plt.title('On-Time (0) vs Delayed (1) Orders')
plt.xlabel('Delivery Status')
plt.ylabel('Number of Orders')
plt.xticks(ticks=[0, 1], labels=['On-Time', 'Delayed'], rotation=0)
plt.tight_layout()
plt.show()

# Group by destination customer state to find shipping bottlenecks
state_performance = df.groupby('customer_state').agg(
    total_orders=('order_id', 'count'),
    avg_delivery_days=('actual_delivery_days', 'mean'),
    delay_rate_pct=('is_delayed', lambda x: (x.sum() / x.count()) * 100)
).reset_index()

# Display top 5 worst states with at least 500 orders
worst_states = state_performance[state_performance['total_orders'] >= 500].sort_values(by='delay_rate_pct', ascending=False).head(5)

print("\n=== TOP 5 WORST REGIONAL BOTTLENECKS ===")
print(worst_states.to_string(index=False))